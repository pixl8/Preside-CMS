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

			it( "should exclude recipient types who's feature is disabled", function(){
				var service = _getService( enabledFeatures=[ "cms" ], disabledFeatures=[ "websiteUsers" ] );
				var expected = [
					  { id="adminUser"  , title="Admin user"             , description=CreateUUId() }
					, { id="anonymous"  , title="Non-authenticated users", description=CreateUUId() }
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

		describe( "prepareParameters()", function(){
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

		describe( "getPreviewParameters()", function(){
			it( "should invoke the corresponding handler action for the given recipient type, passing through any passed args", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var expectedHandler = "email.recipientType.websiteUser.getPreviewParameters";
				var mockParams      = { first_name="test", login_id="me" };

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( true );
				mockColdboxController.$( "runEvent"      ).$args(
					  event          = expectedHandler
					, private        = true
					, prePostExempt  = true
				).$results( mockParams );

				expect( service.getPreviewParameters( recipientType=recipientType ) ).toBe( mockParams );
			} );

			it( "should return an empty struct when no handler action exists", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var expectedHandler = "email.recipientType.websiteUser.getPreviewParameters";

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( false );

				expect( service.getPreviewParameters( recipientType=recipientType ) ).toBe( {} );
			} );

			it( "should return an empty struct when the recipient type does not exist", function(){
				var service         = _getService();
				var recipientType   = CreateUUId();

				expect( service.getPreviewParameters( recipientType=recipientType ) ).toBe( {} );
			} );
		} );

		describe( "getToAddress()", function(){
			it( "should invoke the corresponding handler action for the given recipient type, passing through any passed args", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var expectedHandler = "email.recipientType.websiteUser.getToAddress";
				var mockArgs        = { userId=CreateUUId() };
				var mockAddress     = "test-#CreateUUId()#@test.com";

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( true );
				mockColdboxController.$( "runEvent"      ).$args(
					  event          = expectedHandler
					, eventArguments = { args=mockArgs }
					, private        = true
					, prePostExempt  = true
				).$results( mockAddress );

				expect( service.getToAddress( recipientType=recipientType, args=mockArgs ) ).toBe( mockAddress );
			} );

			it( "should return an empty string when no handler action exists", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var expectedHandler = "email.recipientType.websiteUser.getToAddress";
				var mockArgs        = { userId=CreateUUId() };

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( false );

				expect( service.getToAddress( recipientType=recipientType, args=mockArgs ) ).toBe( "" );
			} );

			it( "should return an empty string when the recipient type does not exist", function(){
				var service         = _getService();
				var recipientType   = CreateUUId();
				var mockArgs        = { userId=CreateUUId() };

				expect( service.getToAddress( recipientType=recipientType, args=mockArgs ) ).toBe( "" );
			} );
		} );

		describe( "getRecipientId()", function(){
			it( "should invoke the corresponding handler action for the given recipient type, passing through any passed args", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var expectedHandler = "email.recipientType.websiteUser.getRecipientId";
				var mockArgs        = { userId=CreateUUId() };
				var mockId          = CreateUUId();

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( true );
				mockColdboxController.$( "runEvent"      ).$args(
					  event          = expectedHandler
					, eventArguments = { args=mockArgs }
					, private        = true
					, prePostExempt  = true
				).$results( mockId );

				expect( service.getRecipientId( recipientType=recipientType, args=mockArgs ) ).toBe( mockId );
			} );

			it( "should return an empty string when no handler action exists", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var expectedHandler = "email.recipientType.websiteUser.getRecipientId";
				var mockArgs        = { userId=CreateUUId() };

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( false );

				expect( service.getRecipientId( recipientType=recipientType, args=mockArgs ) ).toBe( "" );
			} );

			it( "should return an empty string when the recipient type does not exist", function(){
				var service         = _getService();
				var recipientType   = CreateUUId();
				var mockArgs        = { userId=CreateUUId() };

				expect( service.getRecipientId( recipientType=recipientType, args=mockArgs ) ).toBe( "" );
			} );
		} );

		describe( "listRecipientTypeParameters()", function(){
			it( "should return configured parameters for the given recipient type with translated titles and descriptions", function(){
				var service       = _getService();
				var recipientType = "websiteUser"
				var expected      = [{
					  id          = "known_as"
					, title       = "Known as"
					, description = "Blah blah blah test"
					, required    = true
				},{
					  id          = "login_id"
					, title       = "Login ID"
					, description = "Blah blah blah test 2"
					, required    = false
				}];

				for( var param in expected ) {
					service.$( "$translateResource" ).$args( uri="email.recipientType.#recipientType#:param.#param.id#.title"      , defaultValue=param.id ).$results( param.title );
					service.$( "$translateResource" ).$args( uri="email.recipientType.#recipientType#:param.#param.id#.description", defaultValue=""       ).$results( param.description );
				}

				expect( service.listRecipientTypeParameters( recipientType ) ).toBe( expected );
			} );

			it( "should return an empty array when the recipient type does not have any defined parameters", function(){
				expect( _getService().listRecipientTypeParameters( "anonymous" )  ).toBe( [] );
			} );

			it( "should return an empty array when the recipient type does not exist", function(){
				expect( _getService().listRecipientTypeParameters( CreateUUId() )  ).toBe( [] );
			} );
		} );

		describe( "getFilterObjectForRecipientType()", function(){
			it( "should return the configured object for the given type", function(){
				var service = _getService();

				expect( service.getFilterObjectForRecipientType( "adminUser" ) ).toBe( "security_user" );
			} );

			it( "should return an empty string when the type does not have a configured filter object", function(){
				var service = _getService();

				expect( service.getFilterObjectForRecipientType( "anonymous" ) ).toBe( "" );
			} );

			it( "should return an empty string when the type does not exist", function(){
				var service = _getService();

				expect( service.getFilterObjectForRecipientType( CreateUUId() ) ).toBe( "" );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService(
		  struct recipientTypes   = _getTestRecipientTypes()
		, array  enabledFeatures  = [ "cms", "websiteUsers" ]
		, array  disabledFeatures = []
	) {
		var service = createMock( object=CreateObject( "preside.system.services.email.EmailRecipientTypeService" ) );

		mockColdboxController = createStub();
		service.$( "$getColdbox", mockColdboxController );

		for( var feature in enabledFeatures ) {
			service.$( "$isFeatureEnabled" ).$args( feature ).$results( true );
		}
		for( var feature in disabledFeatures  ) {
			service.$( "$isFeatureEnabled" ).$args( feature ).$results( false );
		}

		service.init( configuredRecipientTypes = arguments.recipientTypes );

		return service;
	}

	private struct function _getTestRecipientTypes() {
		return {
			  websiteUser = { feature="websiteUsers", parameters=[ { id="known_as", required=true }, "login_id" ], filterObject="website_user" }
			, adminUser   = { feature="cms", parameters=[ "display_name", "login_id" ], filterObject="security_user" }
			, anonymous   = {}
		};
	}
}