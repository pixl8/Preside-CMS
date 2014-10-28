component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// TESTS
	function test01_addNotification_shouldCreateANewNotificationRecord() {
		var svc   = _getService();
		var newId = CreateUUId();
		var key   = "test.notification";
		var type  = "alert";
		var data  = { related="data" };

		mockNotificationDao.$( "insertData", newId );

		super.assertEquals( newId, svc.addNotification(
			  key  = key
			, type = type
			, data = data
		) );

		super.assertEquals( 1, mockNotificationDao.$callLog().insertData.len() );
		super.assertEquals( { data={
			  key  = key
			, type = type
			, data = SerializeJson( data )
		} }, mockNotificationDao.$callLog().insertData[1] );
	}

	function test02_getUnreadNotificationCount_shouldRetrieveACountOfNotificationRecordsThatAreUnreadAndNotDismissedForTheGivenUser() {
		var svc          = _getService();
		var dummyCount   = 45;
		var dummyRecords = QueryNew( 'notification_count', 'integer', [[ dummyCount ]] );
		var dummyUserId  = CreateUUId()

		mockNotificationDao.$( "selectData" ).$args(
			  selectFields = [ "Count(*) as notification_count" ]
			, filter       = "admin_notification.dismissed = 0 and ( admin_notification_interaction.security_user is null or ( admin_notification_interaction.security_user = :admin_notification_interaction.security_user and admin_notification_interaction.dismissed = 0 and admin_notification_interaction.read = 0 ) )"
			, filterParams = { "admin_notification_interaction.security_user" = dummyUserId }
			, forceJoins = "left"
		).$results( dummyRecords );

		super.assertEquals( dummyCount, svc.getUnreadNotificationCount( dummyUserId ) );
	}

// PRIVATE HELPERS
	private any function _getService() output=false {
		mockNotificationDao = getMockBox().createStub();

		return new preside.system.services.notifications.NotificationService(
			notificationDao = mockNotificationDao
		);
	}
}