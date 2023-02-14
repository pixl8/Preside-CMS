/**
 * The notifications service provides an API to the Preside administrator [[notifications|notifications system]].
 *
 * @singleton
 * @presideService
 */
component autodoc=true displayName="Notification Service" {

// CONSTRUCTOR
	/**
	 * @notificationDao.inject         presidecms:object:admin_notification
	 * @subscriptionDao.inject         presidecms:object:admin_notification_subscription
	 * @consumerDao.inject             presidecms:object:admin_notification_consumer
	 * @topicDao.inject                presidecms:object:admin_notification_topic
	 * @userDao.inject                 presidecms:object:security_user
	 * @coldboxController.inject       coldbox
	 * @configuredTopics.inject        coldbox:setting:notificationTopics
	 * @interceptorService.inject      coldbox:InterceptorService
	 * @emailService.inject            emailService
	 * @permissionService.inject       permissionService
	 * @notificationDirectories.inject presidecms:directories:handlers
	 */
	public any function init(
		  required any   notificationDao
		, required any   consumerDao
		, required any   subscriptionDao
		, required any   userDao
		, required any   topicDao
		, required any   coldboxController
		, required array configuredTopics
		, required any   interceptorService
		, required any   emailService
		, required any   permissionService
		, required array notificationDirectories
	) {
		_setNotificationDao( arguments.notificationDao );
		_setConsumerDao( arguments.consumerDao );
		_setSubscriptionDao( arguments.subscriptionDao );
		_setTopicDao( arguments.topicDao );
		_setColdboxController( arguments.coldboxController );
		_setConfiguredTopics( arguments.configuredTopics );
		_setInterceptorService( arguments.interceptorService );
		_setUserDao( arguments.userDao );
		_setEmailService( arguments.emailService );
		_setPermissionService( arguments.permissionService );
		_setnotificationDirectories( arguments.notificationDirectories );

		_setDefaultConfigurationForTopicsInDb();

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Adds a notification to the system.
	 *
	 * @topic.hint Topic that indicates the specific notification being raised. e.g. 'sync.jobFailed'
	 * @type.hint  Type of the notification, i.e. 'INFO', 'WARNING' or 'ALERT'
	 * @data.hint  Supporting data for the notification. This is used, in combination with the topic, to render the alert for the end users.
	 *
	 */
	public string function createNotification( required string topic, required string type, required struct data ) autodoc=true {
		var topicConfig = getGlobalTopicConfiguration( arguments.topic );
		var args        = Duplicate( arguments );

		_announceInterception( "onCreateNotification", args );

		if ( IsBoolean( topicConfig.save_in_cms ?: "" ) && topicConfig.save_in_cms ) {
			var dataForDbRecord = {
				  topic = arguments.topic
				, type  = arguments.type
				, data  = SerializeJson( arguments.data )
			};
			dataForDbRecord.data_hash = LCase( Hash( dataForDbRecord.data ) );

			var existingNotification = _getNotificationDao().selectData( filter={
				  topic     = dataForDbRecord.topic
				, type      = dataForDbRecord.type
				, data_hash = dataForDbRecord.data_hash
			} );

			if ( existingNotification.recordCount ) {
				createNotificationConsumers( existingNotification.id, args.topic, args.data );
				return existingNotification.id;
			}

			_announceInterception( "preCreateNotification", args );

			args.notificationId = _getNotificationDao().insertData( data=dataForDbRecord );

			_announceInterception( "postCreateNotification", args );

			createNotificationConsumers( args.notificationId, topic, args.data );

			if ( Len( Trim( topicConfig.send_to_email_address ?: "" ) ) ) {
				sendGlobalNotificationEmail(
					  recipient = topicConfig.send_to_email_address
					, topic     = args.topic
					, data      = args
				);
			}
			return args.notificationId;
		}

		if ( Len( Trim( topicConfig.send_to_email_address ?: "" ) ) ) {
			sendGlobalNotificationEmail(
				  recipient = topicConfig.send_to_email_address
				, topic     = arguments.topic
				, data      = args
			);
		}
	}

	/**
	 * Returns a count of unread notifications for the given user id.
	 *
	 * @userId.hint id of the admin user whose unread notification count we wish to retrieve
	 */
	public numeric function getUnreadNotificationCount(
		  required string userId
	) autodoc=true {
		var notificationCount = _getConsumerDao().selectData(
			  filter          = {
				  security_user = arguments.userId
				, read          = false
			  }
			, useCache        = false
			, recordCountOnly = true
		);

		return notificationCount;
	}

	/**
	 * Returns counts of unread notifications by topics for the given user
	 *
	 * @userId.hint  id of the admin user whose unread notifications we wish to retrieve
	 */
	public query function getUnreadTopics(
		  required string userId
		, required numeric maxRows
	) autodoc=true {

		var unreadTopics = QueryNew( "topic, notification_count", "varchar, integer");

		var notificationTopics =  _getNotificationDao().selectData(
			  selectFields = [ "admin_notification.topic" ]
			, groupBy      = "admin_notification.topic"
		);

		for( notificationTopic in notificationTopics ) {
			var queryResult =  _getConsumerDao().selectData(
				  selectFields = [ "admin_notification.topic" ]
				, filter       = {
					  "admin_notification_consumer.security_user" = arguments.userId
					, "admin_notification_consumer.read"          = false
					, "admin_notification.topic"                  = notificationTopic.topic
				  }
				, maxRows      = arguments.maxRows
			);

			if( queryResult.recordCount() ) {
				queryAddRow( unreadTopics );
				querySetCell( unreadTopics, "topic", notificationTopic.topic );
				querySetCell( unreadTopics, "notification_count", queryResult.recordCount() );
			}
		}

		return unreadTopics;
	}

	/**
	 * Returns the latest unread notifications for the given user id. Returns an array of structs, each struct contains id and data keys.
	 *
	 * @userId.hint  id of the admin user whose unread notifications we wish to retrieve
	 * @maxRows.hint maximum number of notifications to retrieve
	 */
	public query function getNotifications(
		  required string  userId
		,          string  topic       = ""
		,          string  dateFrom    = ""
		,          string  dateTo      = ""
		,          numeric startRow    = 1
		,          numeric maxRows     = 10
		,          string  orderBy     = ""
	) autodoc=true {
		var filter         = { "admin_notification_consumer.security_user" = arguments.userId };
		var extraFilters   = [];
		var sortableFields = [ "topic", "datecreated" ];
		var sortableTables = { topic="admin_notification", datecreated="admin_notification_consumer" }

		if ( Len( Trim( arguments.topic ) ) ) {
			filter[ "admin_notification.topic" ] = arguments.topic;
		}

		var sortColumn = ListFirst( arguments.orderBy, " " );
		var sortDir    = ListLen( arguments.orderBy, " " ) > 1 ? ListRest( arguments.orderBy, " " ) : "asc";

		if ( !Len( Trim( sortColumn ) ) || !sortableFields.findNoCase( sortColumn ) ) {
			sortColumn = "datecreated";
			sortDir    = "desc";
		}
		sortDir = sortDir == "asc" ? "asc" : "desc";

		if ( IsDate( arguments.dateFrom ) ) {
			extraFilters.append({
				  filter       = "admin_notification.datecreated >= :dateFrom"
				, filterParams = { dateFrom = { type="date", value=arguments.dateFrom } }
			} );
		}
		if ( IsDate( arguments.dateTo ) ) {
			extraFilters.append({
				  filter       = "admin_notification.datecreated <= :dateTo"
				, filterParams = { dateTo = { type="date", value=arguments.dateTo } }
			} );
		}

		var records = _getConsumerDao().selectData(
			  selectFields = [ "admin_notification.id", "admin_notification.topic", "admin_notification.data", "admin_notification.type", "admin_notification.datecreated", _getConsumerDao().getDbAdapter().escapeEntity( "admin_notification_consumer.read" ) ]
			, filter       = filter
			, extraFilters = extraFilters
			, startRow     = arguments.startRow
			, maxRows      = arguments.maxRows
			, orderby      = "#sortableTables[ sortColumn ]#.#sortColumn# #sortDir#"
		);

		var notifications = Duplicate( records );

		for( var i=1; i<=notifications.recordCount; i++ ) {
			if ( Len( Trim( notifications["data"][i] ?: "" ) ) ) {
				notifications["data"][i] = DeserializeJson( notifications["data"][i] );
			} else {
				notifications["data"][i] = {};
			}
		}

		return notifications;
	}

	/**
	 * Returns a specific notification
	 *
	 * @id.hint ID of the notification
	 */
	public struct function getNotification( required string id ) autodoc=true {
		var record = _getNotificationDao().selectData( id=arguments.id );

		for( var r in record ) {
			r.data = DeserializeJSON( r.data );
			return r;
		}

		return {};
	}

	/**
	 * Returns the count of non-dismissed notifications for the given user id and optional topic
	 *
	 * @userId.hint id of the admin user whose unread notifications we wish to retrieve
	 * @topic.hint  topic by which to filter the notifications
	 */
	public numeric function getNotificationsCount( required string userId, string topic="" ) autodoc=true  {
		var filter  = { "admin_notification_consumer.security_user" = arguments.userId };

		if ( Len( Trim( arguments.topic ) ) ) {
			filter[ "admin_notification.topic" ] = arguments.topic;
		}

		var result = _getConsumerDao().selectData(
			  selectFields = [ "Count( * ) as notification_count" ]
			, filter       = filter
			, useCache     = false
		);

		return Val( result.notification_count ?: "" );
	}


	/**
	 * Renders the given notification topic
	 *
	 * @topic.hint   Topic of the notification
	 * @data.hint    Data associated with the notification
	 * @context.hint Context of the notification
	 */
	public string function renderNotification( required string topic, required struct data, required string context ) autodoc=true {
		var viewletEvent = "renderers.notifications." & arguments.topic & "." & arguments.context;
		if ( _getColdboxController().viewletExists( viewletEvent ) ) {
			return _getColdboxController().renderViewlet(
				  event = viewletEvent
				, args  = arguments.data
			);
		}

		return "";
	}

	/**
	 * Returns array of configured topics
	 *
	 */
	public array function listTopics( string userId="" ) autodoc=true {
		var topics = _getConfiguredTopics();

		if ( Len( Trim( arguments.userId ) ) ) {
			var permittedTopics = [];
			for( var topic in topics ) {
				if ( userHasAccessToTopic( arguments.userId, topic ) ) {
					permittedTopics.append( topic );
				}
			}
			return permittedTopics;
		}

		return topics;
	}

	/**
	 * Returns whether or not the user has access to the given topic
	 *
	 * @userId.hint ID of the user whose permissions we wish to check
	 * @topic.hint  ID of the topic to check
	 */
	public boolean function userHasAccessToTopic( required string userId, required string topic ) autodoc=true {
		var topicGroups = listTopicUserGroups( arguments.topic );

		if ( !topicGroups.len() ) {
			return true;
		}

		var userGroups = _getPermissionService().listUserGroups( arguments.userId );
		for( var topicGroup in topicGroups ) {
			if ( userGroups.find( topicGroup ) ) {
				return true;
			}
		}

		return false;
	}

	/**
	 * Marks notifications as read for a given user
	 *
	 * @notificationIds.hint Array of notification IDs to mark as read
	 * @userId.hint          The id of the user to mark as read for
	 */
	public numeric function markAsRead( required array notificationIds, required string userId ) autodoc=true {
		return _getConsumerDao().updateData(
			  filter = { admin_notification=arguments.notificationIds, security_user=arguments.userId }
			, data   = { read = true }
		);
	}

	/**
	 * Completely discards the given notifications
	 *
	 * @notificationIds.hint Array of notification IDs to dismissed
	 */
	public numeric function dismiss( required array notificationIds ) autodoc=true {
		_getConsumerDao().deleteData( filter = { admin_notification=arguments.notificationIds } );
		return _getNotificationDao().deleteData( filter = { id=arguments.notificationIds } );
	}

	/**
	 * Get subscribed topics for a user. Returns an array of the topic ids
	 *
	 * @userId.hint ID of the user whose subscribed topics we want to fetch
	 *
	 */
	public array function getUserSubscriptions( required string userId ) autodoc=true {
		if ( _getUserDao().dataExists( filter={ id=arguments.userId, subscribed_to_all_notifications=true } ) ) {
			var topics = Duplicate( listTopics() );
			topics.append( "all" );
			return topics;
		}

		var subscriptions = _getSubscriptionDao().selectData( selectFields=[ "topic" ], filter={ security_user=arguments.userId } );

		return subscriptions.recordCount ? ValueArray( subscriptions.topic ) : [];
	}

	/**
	 * Retrieves globally saved configuration settings for a given notification topic
	 *
	 * @topic.hint ID of the topic
	 *
	 */
	public struct function getGlobalTopicConfiguration( required string topic ) autodoc=true {
		var topic = _getTopicDao().selectData( filter={ topic=arguments.topic } );

		for( var t in topic ) { return t; }

		return {};
	}

	/**
	 * Returns an array of user group IDs that the topic is configured to restrict access to
	 *
	 * @topic.hint ID of the topic
	 */
	public array function listTopicUserGroups( required string topic ) autodoc=true {
		var groups = _getTopicDao().selectData( filter={ topic=arguments.topic }, selectFields=[ "available_to_groups.id" ], forcejoins="inner" );
		if ( groups.recordCount ) {
			return ValueArray( groups.id );
		}

		return [];
	}

	/**
	 * Saves configuration for a topic
	 *
	 * @topic.hint         ID of the topic
	 * @configuration.hint Struct containing configuration data
	 *
	 */
	public boolean function saveGlobalTopicConfiguration( required string topic, required struct configuration ) autodoc=true {
		return _getTopicDao().updateData(
			  filter                  = { topic=arguments.topic }
			, data                    = arguments.configuration
			, updateManyToManyRecords = true
		);
	}


	/**
	 * Saves a users subscription preferences
	 *
	 * @userId.hint ID of the user whose subscribed topics we want to save
	 * @topics.hint Array of topics to subscribe to
	 *
	 */
	public void function saveUserSubscriptions( required string userId, required array topics ) autodoc=true {
		var subscriptionDao = _getSubscriptionDao();
		var forDeletion     = [];

		if ( arguments.topics.find( "all" ) ) {
			arguments.topics = listTopics();

			_getUserDao().updateData( id=arguments.userId, data={ subscribed_to_all_notifications=true } );
		} else {
			_getUserDao().updateData( id=arguments.userId, data={ subscribed_to_all_notifications=false } );
		}

		transaction {

			var currentSubscriptions = getUserSubscriptions( arguments.userId );

			for( var topic in currentSubscriptions ) {
				if ( !arguments.topics.find( topic ) ) {
					forDeletion.append( topic );
				}
			}
			if ( forDeletion.len() ) {
				subscriptionDao.deleteData( filter={ security_user = arguments.userId, topic=forDeletion } );
			}

			for( var topic in arguments.topics ) {
				if ( !currentSubscriptions.find( topic ) ) {
					subscriptionDao.insertData({
						  security_user = arguments.userId
						, topic         = topic
					});
				}
			}
		}
	}

	public void function createNotificationConsumers( required string notificationId, required string topic, required struct data ) {
		var subscribedToAll   = _getUserDao().selectData( selectFields=[ "id" ], filter={ subscribed_to_all_notifications=true, active=true } );
		var subscribedToTopic = _getSubscriptionDao().selectData( selectFields=[ "security_user", "get_email_notifications" ], filter={ topic=arguments.topic , "security_user.active"=true } );
		var subscribers = {};
		var interceptorArgs = Duplicate( arguments );

		for( var subscriber in subscribedToAll ){ subscribers[ subscriber.id ] = {}; }
		for( var subscriber in subscribedToTopic ){ subscribers[ subscriber.security_user ] = subscriber; }

		for( var userId in subscribers ){
			if ( userHasAccessToTopic( userId, arguments.topic ) ) {
				var filter = { admin_notification=arguments.notificationId, security_user=userId };
				transaction {
					if ( !_getConsumerDao().updateData( filter=filter, data={ read=false } ) ) {
						interceptorArgs.subscription = subscribers[ userId ];
						_announceInterception( "preCreateNotificationConsumer", interceptorArgs );

						_getConsumerDao().insertData( data={
							  admin_notification = arguments.notificationId
							, security_user      = userId
						} );

						if ( IsBoolean( subscribers[ userId ].get_email_notifications ?: "" ) && subscribers[ userId ].get_email_notifications ) {
							sendSubsciberNotificationEmail( recipient=userId, topic=arguments.topic, notificationId=arguments.notificationId, data=arguments.data );
						}

						_announceInterception( "postCreateNotificationConsumer", interceptorArgs );
					}
				}
			}
		}
	}

	public struct function getUserTopicSubscriptionSettings( required string userId, required string topic ) {
		var subscription = _getSubscriptionDao().selectData( filter={
			  security_user = arguments.userId
			, topic         = arguments.topic
		} );

		for( var sub in subscription ) {
			return sub; // little query to struct hack
		}

		return {};
	}

	public void function saveUserTopicSubscriptionSettings( required string userId, required string topic, required struct settings ) {
		var existingSubscription = getUserTopicSubscriptionSettings( arguments.userId, arguments.topic );

		if ( Len( Trim( existingSubscription.id ?: "" ) ) ) {
			_getSubscriptionDao().updateData(
				  id   = existingSubscription.id
				, data = arguments.settings
			);

			return;
		}

		var data = Duplicate( arguments.settings );
		data.security_user = arguments.userId
		data.topic         = arguments.topic;

		_getSubscriptionDao().insertData( data=data );
	}

	public void function sendSubsciberNotificationEmail( required string recipient, required string topic, required string notificationid, required struct data ) {
		var user = _getUserDao().selectData( id=arguments.recipient, selectFields=[ "email_address", "known_as" ] );


		if ( Len( Trim( user.email_address ?: "" ) ) ) {
			var emailArgs = Duplicate( arguments );
			emailArgs.userName = user.known_as;

			_getEmailService().send(
				  template = "notification"
				, args     = emailArgs
				, to       = [ user.email_address ]
			);
		}
	}

	public void function sendGlobalNotificationEmail( required string recipient, required string topic, required struct data ) {
		var emailArgs       = Duplicate( arguments.data );
			emailArgs.topic = arguments.topic;

		_getEmailService().send(
			  template = "notification"
			, args     = emailArgs
			, to       = ListToArray( arguments.recipient, ",;" )
		);
	}

	public boolean function deleteOldNotifications( any logger ) {

		var keepNotificationsFor = Val( $getPresideSetting( "notification", "keep_notifications_for_days", 0 ) );
		var canLog               = StructKeyExists( arguments, "logger" );
		var canInfo              = canLog && logger.canInfo();
		var canError             = canLog && logger.canError();

		if( keepNotificationsFor == 0 ){
			if ( canInfo ) { logger.info( "Notification cleanup is disabled, no notifications have been deleted." ); }
			return true;
		} else {
			if ( canInfo ) { logger.info( "Deleting old notifications..." ); }

			var notificationsDeleted = $getPresideObject( "admin_notification" ).deleteData(
				  filter       = "datecreated < :datecreated"
				, filterParams = { datecreated = dateAdd( "d", -keepNotificationsFor, DateFormat( now(), "dd-mmm-yyyy" ) ) }
			);

			if ( canInfo ) {
				if ( notificationsDeleted ) {
					logger.info( "Done. Deleted [#NumberFormat( notificationsDeleted )#] notifications." );
				} else {
					logger.info( "Done. No notifications found to delete." );
				}
			}

			return true;
		}
	}

// PRIVATE HELPERS
	private any function _announceInterception( required string state, struct interceptData={} ) {
		_getInterceptorService().processState( argumentCollection=arguments );

		return interceptData.interceptorResult ?: {};
	}

	private void function _setDefaultConfigurationForTopicsInDb() {
		var configuredTopics = _getConfiguredTopics();
		var existingTopics   = _getTopicDao().selectData( selectFields=[ "id", "topic" ] );
		var topicsToDelete   = [];
		var topicsToInsert   = [];
		var notificationDirs = _getNotificationDirectories();
		var notificationIds  = [];

		for( var notificationDir in notificationDirs ){
			var notifications           = [];
			var notificationId          = "";
			var notificationDir         = notificationDir & "/renderers/notifications/";
			var notificationDirExpanded =  expandPath( notificationDir );
			if( directoryExists( notificationDirExpanded ) ){
				notifications = DirectoryList( path=notificationDir, recurse=true, filter="*.cfc" );
			}

			for( var notification in notifications ){
				notificationId = Replace( notification, notificationDirExpanded, "" );
				notificationId = ListDeleteAt( notificationId, ListLen( notificationId, "." ), "." );
				arrayAppend( notificationIds, notificationId );
			}
		}

		for( var notificationId in notificationIds ){
			if ( !configuredTopics.findNoCase( notificationId ) ) {
				configuredTopics.append( notificationId );
			}
		}

		for( var topic in existingTopics ) {
			if ( !configuredTopics.findNoCase( topic.topic ) ) {
				topicsToDelete.append( topic.id );
			}
		}

		existingTopics = ValueArray( existingTopics.topic );
		for( var topic in configuredTopics ) {
			if ( !existingTopics.findNoCase( topic ) ) {
				topicsToInsert.append( topic );
			}
		}

		if ( topicsToDelete.len() ) {
			_getTopicDao().deleteData( filter={ id=topicsToDelete } );
		}
		for( var topic in topicsToInsert ) {
			_getTopicDao().insertData( { topic=topic } );
		}

	}

// GETTERS AND SETTERS
	private any function _getNotificationDao() {
		return _notificationDao;
	}
	private void function _setNotificationDao( required any notificationDao ) {
		_notificationDao = arguments.notificationDao;
	}

	private any function _getConsumerDao() {
		return _consumerDao;
	}
	private void function _setConsumerDao( required any consumerDao ) {
		_consumerDao = arguments.consumerDao;
	}

	private any function _getSubscriptionDao() {
		return _subscriptionDao;
	}
	private void function _setSubscriptionDao( required any subscriptionDao ) {
		_subscriptionDao = arguments.subscriptionDao;
	}

	private any function _getTopicDao() output=false {
		return _topicDao;
	}
	private void function _setTopicDao( required any topicDao ) output=false {
		_topicDao = arguments.topicDao;
	}

	private any function _getColdboxController() {
		return _coldboxController;
	}
	private void function _setColdboxController( required any coldboxController ) {
		_coldboxController = arguments.coldboxController;
	}

	private any function _getConfiguredTopics() {
		return _configuredTopics;
	}
	private void function _setConfiguredTopics( required any configuredTopics ) {
		_configuredTopics = arguments.configuredTopics;
	}

	private any function _getInterceptorService() {
		return _interceptorService;
	}
	private void function _setInterceptorService( required any interceptorService ) {
		_interceptorService = arguments.interceptorService;
	}

	private any function _getUserDao() {
		return _userDao;
	}
	private void function _setUserDao( required any userDao ) {
		_userDao = arguments.userDao;
	}

	private any function _getEmailService() {
		return _emailService;
	}
	private void function _setEmailService( required any emailService ) {
		_emailService = arguments.emailService;
	}

	private any function _getPermissionService() {
		return _permissionService;
	}
	private void function _setPermissionService( required any permissionService ) {
		_permissionService = arguments.permissionService;
	}

	private any function _getNotificationDirectories() {
		return _notificationDirectories;
	}
	private any function _setNotificationDirectories( required array notificationDirectories ) {
		_notificationDirectories = arguments.notificationDirectories;
	}
}