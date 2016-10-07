component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// TESTS
	function test01_saveEmailLogs_shouldSaveEmailLogs_forAllFromTheSite() {
		var service = _getEmailLogService();
		var id       = createUUID();
		var data     = { from_address='sysadmin@test.com', to_address='user@test.com', subject='test subject', html_body="test html_body", text_body="test text_body", status="sent" };

		mockObject.$( "insertData" ).$args( data ).$results( id );
		expect( service.saveEmailLogs( argumentCollection=data ) ).toBeNull();
	}

	function test02_getEmailLogs_shouldReturnQuery_forAllEmailActivities() {
		var service     = _getEmailLogService();
		var id           = createUUID();
		var dummyResults = queryNew( "id,from_address,to_address,subject,html_body,text_body,status", "varchar,varchar,varchar,varchar,varchar,date,date",{ id=id, from_address='sysadmin@test.com', to_address='user@test.com', subject='test subject', html_body="test html_body", text_body="test text_body", status="sent" } );

		mockObject.$( "selectData" ).$results( dummyResults );
		expect( service.getEmailLogs().recordcount ).toBe( 1 );
	}

	function test03_getEmailLogs_shouldReturnEmptyQuery_whenNoEmailLogs() {
		var service     = _getEmailLogService();
		var id           = createUUID();
		var dummyResults = queryNew( "id,from_address,to_address,subject,html_body,text_body,status", "varchar,varchar,varchar,varchar,varchar,date,date" );

		mockObject.$( "selectData" ).$results( dummyResults );
		expect( service.getEmailLogs().recordcount ).toBe( 0 );
	}

	function test04_getEmailLog_shouldReturnQuery_forSelectedEmailId() {
		var service     = _getEmailLogService();
		var id           = createUUID();
		var dummyResults = queryNew( "id,from_address,to_address,subject,html_body,text_body,status", "varchar,varchar,varchar,varchar,varchar,date,date",{ id=id, from_address='sysadmin@test.com', to_address='user@test.com', subject='test subject', html_body="test html_body", text_body="test text_body", status="sent" } );

		mockObject.$( "selectData" ).$results( dummyResults );
		expect( service.getEmailLog( id=id ).recordcount ).toBe( 1 );
	}

	function test05_getEmailLog_shouldReturnEmptyQuery_forSelectedEmailId() {
		var service     = _getEmailLogService();
		var id           = createUUID();
		var dummyResults = queryNew( "id,from_address,to_address,subject,html_body,text_body,status", "varchar,varchar,varchar,varchar,varchar,date,date" );

		mockObject.$( "selectData" ).$results( dummyResults );
		expect( service.getEmailLog( id=id ).recordcount ).toBe( 0 );
	}

	function test06_deleteEmailLog_shouldDelete_selectedEmailLog() {
		var service     = _getEmailLogService();
		var id           = createUUID();

		mockObject.$( "deleteData" ).$results( 1 );
		expect( service.deleteEmailLog( id=id ) ).toBeNull();
	}

	function test07_deleteAllEmails_shouldDelete_allEmailLog() {
		var service      = _getEmailLogService();

		mockObject.$( "deleteData" ).$results( 1 );
		expect( service.deleteAllEmails( forceDeleteAll=true ) ).toBeNull();
	}

// private helpers
	private any function _getEmailLogService() output=false {
		variables.mockObject = CreateStub();
		mockEmailLogService  = getMockBox().createMock( object=new preside.system.services.email.EmailLogService() );
		mockEmailLogService.$( "$getPresideObject" ).$args( "email_logs" ).$results( mockObject  );

		return mockEmailLogService;
	}

}