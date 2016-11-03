component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "listRecipientTypes()", function(){
			it( "should return an array of the configured recipient types with translated titles and descriptions, ordered by title", function(){
				var service = _getService();
				var expected = [
					  { id="adminUser"  , title="Admin user"             , description=CreateUUId() }
					, { id="anonymous"  , title="Non-authenticated users", description=CreateUUId() }
					, { id="websiteUser", title="Website user"           , description=CreateUUId() }
				];

				for( var type in expected ) {
					service.$( "$translateResource" ).$args( uri="email.recipienttype.#type.id#:title"      , defaultValue=type.id ).$results( type.title       );
					service.$( "$translateResource" ).$args( uri="email.recipienttype.#type.id#:description", defaultValue=""      ).$results( type.description );
				}

				expect( service.listRecipientTypes() ).toBe( expected );
			} );
		} );

		describe( "recipientTypeExists()", function(){
			it( "should return true when the recipient type is present in the configuration", function(){
				var service = _getService();

				expect( service.recipientTypeExists( "anonymous" ) ).toBe( true );
			} );

			it( "should return false when the recipient type is not present in the configuration", function(){
				var service = _getService();

				expect( service.recipientTypeExists( CreateUUId() ) ).toBe( false );
			} );
		} );

		describe( "prepareParameters", function(){
			it( "should invoke the corresponding handler action for the given recipient type, passing through any passed args", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var expectedHandler = "email.recipientType.websiteUser.prepareParameters";
				var mockArgs        = { userId=CreateUUId() };
				var mockParams      = { first_name="test", login_id="me" };

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( true );
				mockColdboxController.$( "runEvent"      ).$args(
					  event          = expectedHandler
					, eventArguments = { args=mockArgs }
					, private        = true
					, prePostExempt  = true
				).$results( mockParams );

				expect( service.prepareParameters( recipientType=recipientType, args=mockArgs ) ).toBe( mockParams );
			} );

			it( "should return an empty struct when no handler action exists", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var expectedHandler = "email.recipientType.websiteUser.prepareParameters";
				var mockArgs        = { userId=CreateUUId() };

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( false );

				expect( service.prepareParameters( recipientType=recipientType, args=mockArgs ) ).toBe( {} );
			} );

			it( "should return an empty struct when the recipient type does not exist", function(){
				var service         = _getService();
				var recipientType   = CreateUUId();
				var mockArgs        = { userId=CreateUUId() };

				expect( service.prepareParameters( recipientType=recipientType, args=mockArgs ) ).toBe( {} );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService( struct recipientTypes=_getTestRecipientTypes() ) {
		var service = createMock( object=new preside.system.services.email.EmailRecipientTypeService(
			  configuredRecipientTypes = arguments.recipientTypes
		) );

		mockColdboxController = createStub();
		service.$( "$getColdbox", mockColdboxController );

		return service;
	}

	private struct function _getTestRecipientTypes() {
		return {
			  websiteUser = { parameters=[ { id="known_as", required=true }, "login_id" ] }
			, adminUser   = { parameters=[ "display_name", "login_id" ] }
			, anonymous   = {}
		};
	}
}