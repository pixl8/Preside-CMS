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
		var queryResult = _getNotificationDao().selectData(
			  selectFields = [ "Count(*) as notification_count" ]
			, forceJoins   = "left"
			, filter       = "admin_notification_consumer.security_user is null or ( admin_notification_consumer.security_user = :admin_notification_consumer.security_user and admin_notification_consumer.dismissed = 0 and admin_notification_consumer.read = 0 )"
			, filterParams = { "admin_notification_consumer.security_user" = arguments.userId }
		);

		return Val( queryResult.notification_count ?: "" );
	}

	/**
	 * Returns the latest unread notifications for the given user id. Returns an array of structs, each struct contains id and data keys.
	 *
	 * @userId.hint  id of the admin user who's unread notifications we wish to retrieve
	 * @maxRows.hint maximum number of notifications to retrieve
	 */
	public array function getUnreadNotifications( required string userId, numeric maxRows=10 ) output=false autodoc=true {
		var records = _getNotificationDao().selectData(
			  selectFields = [ "id", "data" ]
			, maxRows      = arguments.maxRows
			, filter       = {
				  "admin_notification_consumer.security_user" = arguments.userId
				, "admin_notification_consumer.dismissed"     = false
				, "admin_notification_consumer.read"          = false
			  }
		);
		var notifications = [];

		for( var record in records ) {
			notifications.append( {
				  id   = record.id
				, data = Len( Trim( record.data ?: "" ) ) ? DeserializeJson( record.data ) : {}
			} );
		}

		return notifications;
	}

	/**
	 * Renders the given notification topic
	 *
	 * @topic.hint Topic of the notification
	 * @data.hint  Data associated with the notification
	 */
	public string function renderNotification( required string topic, required struct data ) output=false autodoc=true {
		return _getColdboxController().renderViewlet(
			  event = "renderers.notification." & arguments.topic
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