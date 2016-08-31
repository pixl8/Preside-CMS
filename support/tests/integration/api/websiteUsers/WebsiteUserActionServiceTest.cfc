component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "recordAction", function(){
			it( "should save the action to the database, serializing the detail to json", function(){
				var service = _getService();
				var dbId    = CreateUUId();
				var userId  = CreateUUId();
				var action  = "logout";
				var type    = "login";
				var detail  = { test=CreateUUId() };

				mockActionDao.$( "insertData" ).$args( {
					  user       = userId
					, action     = action
					, type       = type
					, detail     = SerializeJson( detail )
					, uri        = cgi.request_url
					, user_ip    = cgi.remote_addr
					, user_agent = cgi.http_user_agent
				} ).$results( dbId );

				var actionId = service.recordAction(
					  userId = userId
					, action = action
					, type   = type
					, detail = detail
				);

				expect( actionId ).toBe( dbId );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService() {
		var service = createMock( object=new preside.system.services.websiteUsers.WebsiteUserActionService() );

		mockActionDao = CreateStub();

		service.$( "$getPresideObject" ).$args( "website_user_action" ).$results( mockActionDao );

		return service;
	}
}