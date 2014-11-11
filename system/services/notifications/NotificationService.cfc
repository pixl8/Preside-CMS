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
	 * @coldboxController.inject  coldbox
	 * @configuredTopics.inject   coldbox:setting:notificationTopics
	 */
	public any function init( required any notificationDao, required any consumerDao, required any subscriptionDao, required any coldboxController, required array configuredTopics ) output=false {
		_setNotificationDao( arguments.notificationDao );
		_setConsumerDao( arguments.consumerDao );
		_setSubscriptionDao( arguments.subscriptionDao );
		_setColdboxController( arguments.coldboxController );
		_setConfiguredTopics( arguments.configuredTopics );

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
		var notificationId = _getNotificationDao().insertData( data={
			  topic = arguments.topic
			, type  = arguments.type
			, data  = SerializeJson( arguments.data )
		} );

		createNotificationConsumers( notificationId, topic );

		return notificationId;
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

	public void function createNotificationConsumers( required string notificationId, required string topic ) output=false {
		var subscribers = _getSubscriptionDao().selectData( selectFields=[ "security_user" ], filter={ topic=arguments.topic } );

		for( var subscriber in subscribers ){
			_getConsumerDao().insertData( data={
				  admin_notification = arguments.notificationId
				, security_user      = subscriber.security_user
			} );
		}
	}

// PRIVATE HELPERS

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
}