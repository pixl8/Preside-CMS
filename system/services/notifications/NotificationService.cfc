/**
 * The notifications service provides an API to the PresideCMS administrator notifications system
 *
 */
component output=false autodoc=true displayName="Notification Service" {

// CONSTRUCTOR
	/**
	 * @notificationDao.inject    presidecms:object:admin_notification
	 * @subscriptionDao.inject    presidecms:object:admin_notification_subscription
	 * @consumerDao.inject        presidecms:object:admin_notification_consumer
	 * @userDao.inject            presidecms:object:security_user
	 * @coldboxController.inject  coldbox
	 * @configuredTopics.inject   coldbox:setting:notificationTopics
	 * @interceptorService.inject coldbox:InterceptorService
	 */
	public any function init( required any notificationDao, required any consumerDao, required any subscriptionDao, required any userDao, required any coldboxController, required array configuredTopics, required any interceptorService ) output=false {
		_setNotificationDao( arguments.notificationDao );
		_setConsumerDao( arguments.consumerDao );
		_setSubscriptionDao( arguments.subscriptionDao );
		_setColdboxController( arguments.coldboxController );
		_setConfiguredTopics( arguments.configuredTopics );
		_setInterceptorService( arguments.interceptorService );
		_setUserDao( arguments.userDao );

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
	public string function createNotification( required string topic, required string type, required struct data ) output=false autodoc=true {
		var args = Duplicate( arguments );
		var data = {
			  topic = arguments.topic
			, type  = arguments.type
			, data  = SerializeJson( arguments.data )
		};
		data.data_hash = LCase( Hash( data.data ) );

		var existingNotification = _getNotificationDao().selectData( filter={
			  topic     = data.topic
			, type      = data.type
			, data_hash = data.data_hash
		} );

		if ( existingNotification.recordCount ) {
			createNotificationConsumers( existingNotification.id, args.topic );
			return existingNotification.id;
		}

		_announceInterception( "preCreateNotification", args );

		args.notificationId = _getNotificationDao().insertData( data=data );

		_announceInterception( "postCreateNotification", args );

		createNotificationConsumers( args.notificationId, topic );

		return args.notificationId;
	}

	/**
	 * Returns a count of unread notifications for the given user id.
	 *
	 * @userId.hint id of the admin user who's unread notification count we wish to retrieve
	 */
	public numeric function getUnreadNotificationCount( required string userId ) output=false autodoc=true {
		var queryResult = _getConsumerDao().selectData(
			  selectFields = [ "Count(*) as notification_count" ]
			, filter       = { security_user = arguments.userId, read = false }
		);

		return Val( queryResult.notification_count ?: "" );
	}

	/**
	 * Returns counts of unread notifications by topics for the given user
	 *
	 * @userId.hint  id of the admin user who's unread notifications we wish to retrieve
	 */
	public query function getUnreadTopics( required string userId ) output=false autodoc=true {
		return _getConsumerDao().selectData(
			  selectFields = [ "admin_notification.topic", "Count(*) as notification_count" ]
			, filter       = {
				  "admin_notification_consumer.security_user" = arguments.userId
				, "admin_notification_consumer.read"          = false
			  }
			, groupBy      = "admin_notification.topic"
		);
	}

	/**
	 * Returns the latest unread notifications for the given user id. Returns an array of structs, each struct contains id and data keys.
	 *
	 * @userId.hint  id of the admin user who's unread notifications we wish to retrieve
	 * @maxRows.hint maximum number of notifications to retrieve
	 */
	public array function getNotifications( required string userId, numeric maxRows=10, string topic="" ) output=false autodoc=true {
		var filter  = {
			  "admin_notification_consumer.security_user" = arguments.userId
		};

		if ( Len( Trim( arguments.topic ) ) ) {
			filter[ "admin_notification.topic" ] = arguments.topic;
		}

		var records = _getConsumerDao().selectData(
			  selectFields = [ "admin_notification.id", "admin_notification.topic", "admin_notification.data", "admin_notification.type", "admin_notification.datecreated", "admin_notification_consumer.read" ]
			, maxRows      = arguments.maxRows
			, filter       = filter
			, orderby      = "admin_notification_consumer.datecreated desc"
		);
		var notifications = [];

		for( var record in records ) {
			record.data = Len( Trim( record.data ?: "" ) ) ? DeserializeJson( record.data ) : {};
			notifications.append( record );
		}

		return notifications;
	}

	/**
	 * Returns a specific notification
	 *
	 * @id.hint ID of the notification
	 */
	public struct function getNotification( required string id ) output=false autodoc=true {
		var record = _getNotificationDao().selectData( id=arguments.id );

		for( var r in record ) {
			r.data = DeserializeJSON( r.data );
			return r;
		}

		return {};
	}


	/**
	 * Renders the given notification topic
	 *
	 * @topic.hint Topic of the notification
	 * @data.hint  Data associated with the notification
	 */
	public string function renderNotification( required string topic, required struct data, required string context ) output=false autodoc=true {
		return _getColdboxController().renderViewlet(
			  event = "renderers.notifications." & arguments.topic & "." & arguments.context
			, args  = arguments.data
		);
	}

	/**
	 * Returns array of configured topics
	 *
	 */
	public array function listTopics() output=false autodoc=true {
		return _getConfiguredTopics();
	}

	/**
	 * Marks notifications as read for a given user
	 *
	 * @notificationIds.hint Array of notification IDs to mark as read
	 * @userId.hint          The id of the user to mark as read for
	 */
	public numeric function markAsRead( required array notificationIds, required string userId ) output=false autodoc=true {
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
	public numeric function dismiss( required array notificationIds ) output=false autodoc=true {
		return _getNotificationDao().deleteData( filter = { id=arguments.notificationIds } );
	}

	/**
	 * Get subscribed topics for a user. Returns an array of the topic ids
	 *
	 * @userId.hint ID of the user who's subscribed topics we want to fetch
	 *
	 */
	public array function getUserSubscriptions( required string userId ) output=false autodoc=true {
		if ( _getUserDao().dataExists( filter={ id=arguments.userId, subscribed_to_all_notifications=true } ) ) {
			var topics = Duplicate( listTopics() );
			topics.append( "all" );
			return topics;
		}

		var subscriptions = _getSubscriptionDao().selectData( selectFields=[ "topic" ], filter={ security_user=arguments.userId } );

		return subscriptions.recordCount ? ValueArray( subscriptions.topic ) : [];
	}


	/**
	 * Saves a users subscription preferences
	 *
	 * @userId.hint ID of the user who's subscribed topics we want to save
	 * @topics.hint Array of topics to subscribe to
	 *
	 */
	public void function saveUserSubscriptions( required string userId, required array topics ) output=false autodoc=true {
		var subscriptionDao = _getSubscriptionDao();
		var forDeletion     = [];

		if ( arguments.topics.find( "all" ) ) {
			arguments.topics = [];

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

	public void function createNotificationConsumers( required string notificationId, required string topic ) output=false {
		var subscribedToAll   = _getUserDao().selectData( selectFields=[ "id" ], filter={ subscribed_to_all_notifications=true } );
		var subscribedToTopic = _getSubscriptionDao().selectData( selectFields=[ "security_user" ], filter={ topic=arguments.topic } );
		var subscribers = {};

		for( var subscriber in subscribedToAll ){ subscribers[ subscriber.id ] = true; }
		for( var subscriber in subscribedToTopic ){ subscribers[ subscriber.security_user ] = true; }

		for( var userId in subscribers ){
			var filter = { admin_notification=arguments.notificationId, security_user=userId };
			transaction {
				if ( !_getConsumerDao().updateData( filter=filter, data={ read=false } ) ) {
					_announceInterception( "preCreateNotificationConsumer", arguments );
					_getConsumerDao().insertData( data={
						  admin_notification = arguments.notificationId
						, security_user      = userId
					} );
				}
			}
		}
	}

	public struct function getUserTopicSubscriptionSettings( required string userId, required string topic ) output=false {
		var subscription = _getSubscriptionDao().selectData( filter={
			  security_user = arguments.userId
			, topic         = arguments.topic
		} );

		for( var sub in subscription ) {
			return sub; // little query to struct hack
		}

		return {};
	}

// PRIVATE HELPERS
	private any function _announceInterception( required string state, struct interceptData={} ) output=false {
		_getInterceptorService().processState( argumentCollection=arguments );

		return interceptData.interceptorResult ?: {};
	}


// GETTERS AND SETTERS
	private any function _getNotificationDao() output=false {
		return _notificationDao;
	}
	private void function _setNotificationDao( required any notificationDao ) output=false {
		_notificationDao = arguments.notificationDao;
	}

	private any function _getConsumerDao() output=false {
		return _consumerDao;
	}
	private void function _setConsumerDao( required any consumerDao ) output=false {
		_consumerDao = arguments.consumerDao;
	}

	private any function _getSubscriptionDao() output=false {
		return _subscriptionDao;
	}
	private void function _setSubscriptionDao( required any subscriptionDao ) output=false {
		_subscriptionDao = arguments.subscriptionDao;
	}

	private any function _getColdboxController() output=false {
		return _coldboxController;
	}
	private void function _setColdboxController( required any coldboxController ) output=false {
		_coldboxController = arguments.coldboxController;
	}

	private any function _getConfiguredTopics() output=false {
		return _configuredTopics;
	}
	private void function _setConfiguredTopics( required any configuredTopics ) output=false {
		_configuredTopics = arguments.configuredTopics;
	}

	private any function _getInterceptorService() output=false {
		return _interceptorService;
	}
	private void function _setInterceptorService( required any interceptorService ) output=false {
		_interceptorService = arguments.interceptorService;
	}

	private any function _getUserDao() output=false {
		return _userDao;
	}
	private void function _setUserDao( required any userDao ) output=false {
		_userDao = arguments.userDao;
	}
}