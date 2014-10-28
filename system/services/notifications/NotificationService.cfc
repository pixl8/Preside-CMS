/**
 * The notifications service provides an API to the PresideCMS administrator notifications system
 *
 */
component output=false autodoc=true displayName="Notification Service" {

// CONSTRUCTOR
	/**
	 * @notificationDao.inject    presidecms:object:admin_notification
	 */
	public any function init( required any notificationDao) output=false {
		_setNotificationDao( arguments.notificationDao );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Adds a notification to the system.
	 *
	 * @key.hint  Key that indicates the specific notification being raised. e.g. 'sync.jobFailed'
	 * @type.hint Type of the notification, i.e. 'INFO', 'WARNING' or 'ALERT'
	 * @data.hint Supporting data for the notification. This is used, in combination with the key, to render the alert for the end users.
	 *
	 */
	public string function addNotification( required string key, required string type, required struct data ) output=false autodoc=true {
		return _getNotificationDao().insertData( data={
			  key  = arguments.key
			, type = arguments.type
			, data = SerializeJson( arguments.data )
		} );
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
			, filter       = "admin_notification.dismissed = 0 and ( admin_notification_interaction.security_user is null or ( admin_notification_interaction.security_user = :admin_notification_interaction.security_user and admin_notification_interaction.dismissed = 0 and admin_notification_interaction.read = 0 ) )"
			, filterParams = { "admin_notification_interaction.security_user" = arguments.userId }
		);

		return Val( queryResult.notification_count ?: "" );
	}

	/**
	 * Returns the latest unread notifications for the given user id
	 *
	 * @userId.hint  id of the admin user who's unread notifications we wish to retrieve
	 * @maxRows.hint maximum number of notifications to retrieve
	 */
	public query function getUnreadNotifications( required string userId, numeric maxRows=10 ) output=false {

	}


// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getNotificationDao() output=false {
		return _notificationDao;
	}
	private void function _setNotificationDao( required any notificationDao ) output=false {
		_notificationDao = arguments.notificationDao;
	}
}