component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// TESTS
	function test01_createNotification_shouldCreateANewNotificationRecord() {
		var svc   = _getService();
		var newId = CreateUUId();
		var topic = "test.notification";
		var type  = "alert";
		var data  = { related="data" };

		svc.$( "createNotificationConsumers" );

		mockNotificationDao.$( "insertData" ).$args(
			data={
				  topic  = topic
				, type = type
				, data = SerializeJson( data )
			}
		).$results( newId );

		super.assertEquals( newId, svc.createNotification(
			  topic = topic
			, type  = type
			, data  = data
		) );

		super.assertEquals( 1, svc.$callLog().createNotificationConsumers.len() );
		super.assertEquals( [ newId, topic ], svc.$callLog().createNotificationConsumers[1] );
	}

	function test02_createNotificationConsumers_shouldCreateAConsumerRecordForEachUserSubscribedToTheGivenTopic() {
		var svc              = _getService();
		var dummySubscribers = QueryNew( 'security_user', 'varchar', [ [ CreateUUId() ], [ CreateUUId() ], [ CreateUUId() ], [ CreateUUId() ], [ CreateUUId() ] ] );
		var notificationid   = CreateUUId();
		var topic            = "mytopic";

		mockSubscriptionDao.$( "selectData" ).$args( selectFields=[ "security_user" ], filter={ topic=topic } ).$results( dummySubscribers );
		mockConsumerDao.$( "insertData" );

		svc.createNotificationConsumers( notificationId, topic );

		super.assertEquals( dummySubscribers.recordCount, mockConsumerDao.$callLog().insertData.len() );
	}

	function test03_getUnreadNotificationCount_shouldRetrieveACountOfNotificationRecordsThatAreUnreadAndNotDismissedForTheGivenUser() {
		var svc          = _getService();
		var dummyCount   = 45;
		var dummyRecords = QueryNew( 'notification_count', 'integer', [[ dummyCount ]] );
		var dummyUserId  = CreateUUId()

		mockNotificationDao.$( "selectData" ).$args(
			  selectFields = [ "Count(*) as notification_count" ]
			, filter       = "admin_notification_consumer.security_user is null or ( admin_notification_consumer.security_user = :admin_notification_consumer.security_user and admin_notification_consumer.dismissed = 0 and admin_notification_consumer.read = 0 )"
			, filterParams = { "admin_notification_consumer.security_user" = dummyUserId }
			, forceJoins   = "left"
		).$results( dummyRecords );

		super.assertEquals( dummyCount, svc.getUnreadNotificationCount( dummyUserId ) );
	}

	function test04_getUnreadNotifications_shouldRetrieveLatestUnreadNotificationsForTheGivenUser() {
		var svc          = _getService();
		var dummyRecords = QueryNew( 'id,data', 'varchar,varchar', [ [ CreateUUId(), '{ "some":"data" }' ], [ CreateUUId(), '{ "some":"data" }' ], [ CreateUUId(), '{ "some":"data" }' ], [ CreateUUId(), '{ "some":"data" }' ], [ CreateUUId(), '{ "some":"data" }' ], [ CreateUUId(), '{ "some":"data" }' ] ] );
		var dummyUserId  = CreateUUId();
		var maxRows      = 100;
		var expected     = [];

		for( var r in dummyRecords ){
			expected.append( {
				  id = r.id
				, data = DeSerializeJson( r.data )
			} );
		}

		mockNotificationDao.$( "selectData" ).$args(
			  selectFields = [ "id", "data" ]
			, maxRows      = maxRows
			, filter       = {
				  "admin_notification_consumer.security_user" = dummyUserId
				, "admin_notification_consumer.dismissed"     = false
				, "admin_notification_consumer.read"          = false
			 }
		).$results( dummyRecords );

		super.assertEquals( expected, svc.getUnreadNotifications( dummyUserId, maxRows ) );
	}

	function test05_renderNotification_shouldMakeAColdboxRenderViewletCallToTheAdminNotificationsRendererUsingTheTheTopicAsHandlerAction() {
		var svc             = _getService();
		var renderedContent = CreateUUId();
		var topic           = "sometopic";
		var data            = { some="argument", flag=true };

		mockColdboxController.$( "renderViewlet" ).$args( event="renderers.notification.#topic#", args=data ).$results( renderedContent );

		super.assertEquals( renderedContent, svc.renderNotification( topic, data ) );
	}

	function test06_listTopics_shouldReturnArrayOfConfiguredTopics() {
		var svc = _getService();

		super.assertEquals( dummyTopics, svc.listTopics() );
	}

// PRIVATE HELPERS
	private any function _getService() output=false {
		mockNotificationDao   = getMockBox().createStub();
		mockSubscriptionDao   = getMockBox().createStub();
		mockConsumerDao       = getMockBox().createStub();
		mockColdboxController = getMockBox().createStub();

		dummyTopics = [ "topic_1", "topic_2", "topic_3" ];

		var notificationService = new preside.system.services.notifications.NotificationService(
			  notificationDao   = mockNotificationDao
			, subscriptionDao   = mockSubscriptionDao
			, consumerDao       = mockConsumerDao
			, coldboxController = mockColdboxController
			, configuredTopics  = dummyTopics
		);

		return getMockBox().createMock( object=notificationService );
	}
}