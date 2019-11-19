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

			it( "should exclude recipient types whose feature is disabled", function(){
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
				var recipientId     = CreateUUId();
				var expectedHandler = "email.recipientType.websiteUser.prepareParameters";
				var mockArgs        = { userId=CreateUUId() };
				var mockParams      = { first_name="test", login_id="me" };
				var template        = CreateUUId();
				var templateDetail  = { test=CreateUUId() };

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( true );
				mockColdboxController.$( "runEvent"      ).$args(
					  event          = expectedHandler
					, private        = true
					, prePostExempt  = true
					, eventArguments = {
						  args           = mockArgs
						, recipientId    = recipientId
						, template       = template
						, templateDetail = templateDetail
					  }
				).$results( mockParams );

				expect( service.prepareParameters(
					  recipientType  = recipientType
					, recipientId    = recipientId
					, args           = mockArgs
					, template       = template
					, templateDetail = templateDetail
				) ).toBe( mockParams );
			} );

			it( "should return an empty struct when no handler action exists", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var recipientId     = CreateUUId();
				var expectedHandler = "email.recipientType.websiteUser.prepareParameters";
				var mockArgs        = { userId=CreateUUId() };

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( false );

				expect( service.prepareParameters( recipientType=recipientType, recipientId=recipientId, args=mockArgs ) ).toBe( {} );
			} );

			it( "should return an empty struct when the recipient type does not exist", function(){
				var service         = _getService();
				var recipientType   = CreateUUId();
				var mockArgs        = { userId=CreateUUId() };

				expect( service.prepareParameters( recipientType=recipientType, recipientId=CreateUUId(), args=mockArgs ) ).toBe( {} );
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
			it( "should invoke the corresponding handler action for the given recipient type, passing through the passed recipient ID", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var expectedHandler = "email.recipientType.websiteUser.getToAddress";
				var recipientId     = CreateUUId();
				var mockAddress     = "test-#CreateUUId()#@test.com";

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( true );
				mockColdboxController.$( "runEvent"      ).$args(
					  event          = expectedHandler
					, eventArguments = { recipientId=recipientId }
					, private        = true
					, prePostExempt  = true
				).$results( mockAddress );

				expect( service.getToAddress( recipientType=recipientType, recipientId=recipientId ) ).toBe( mockAddress );
			} );

			it( "should return an empty string when no handler action exists", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var expectedHandler = "email.recipientType.websiteUser.getToAddress";
				var recipientId     = CreateUUId();

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( false );

				expect( service.getToAddress( recipientType=recipientType, recipientId=recipientId ) ).toBe( "" );
			} );

			it( "should return an empty string when the recipient type does not exist", function(){
				var service         = _getService();
				var recipientType   = CreateUUId();
				var recipientId     = CreateUUId();

				expect( service.getToAddress( recipientType=recipientType, recipientId=recipientId ) ).toBe( "" );
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

		describe( "getGridFieldsForRecipientType()", function(){
			it( "should return the configured grid fields for the given type", function(){
				var service = _getService();

				expect( service.getGridFieldsForRecipientType( "adminUser" ) ).toBe( [ "known_as", "email_address" ] );
			} );

			it( "should return an empty array when the type does not have a configured grid fields", function(){
				var service = _getService();

				expect( service.getGridFieldsForRecipientType( "anonymous" ) ).toBe( [] );
			} );

			it( "should return an empty array when the type does not exist", function(){
				var service = _getService();

				expect( service.getGridFieldsForRecipientType( CreateUUId() ) ).toBe( [] );
			} );
		} );

		describe( "getRecipientIdLogPropertyForRecipientType()", function(){
			it( "should return the configured object for the given type", function(){
				var service = _getService();

				expect( service.getRecipientIdLogPropertyForRecipientType( "adminUser" ) ).toBe( "security_user_recipient" );
			} );

			it( "should return an empty string when the type does not have a configured filter object", function(){
				var service = _getService();

				expect( service.getRecipientIdLogPropertyForRecipientType( "anonymous" ) ).toBe( "" );
			} );

			it( "should return an empty string when the type does not exist", function(){
				var service = _getService();

				expect( service.getRecipientIdLogPropertyForRecipientType( CreateUUId() ) ).toBe( "" );
			} );
		} );

		describe( "getUnsubscribeLink()", function(){
			it( "should invoke the corresponding handler action for the given recipient type, passing through the passed recipient and template IDs", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var expectedHandler = "email.recipientType.websiteUser.getUnsubscribeLink";
				var recipientId     = CreateUUId();
				var templateId      = CreateUUId();
				var mockLink        = CreateUUId();

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( true );
				mockColdboxController.$( "runEvent"      ).$args(
					  event          = expectedHandler
					, eventArguments = { recipientId=recipientId, templateId=templateId }
					, private        = true
					, prePostExempt  = true
				).$results( mockLink );

				expect( service.getUnsubscribeLink( recipientType=recipientType, recipientId=recipientId, templateId=templateId ) ).toBe( mockLink );
			} );

			it( "should raise an interception point to attempt creating the link if not specific handler is found", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var expectedHandler = "email.recipientType.websiteUser.getUnsubscribeLink";
				var recipientId     = CreateUUId();
				var templateId      = CreateUUId();
				var mockLink        = CreateUUId();

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( false );

				service.getUnsubscribeLink( recipientType=recipientType, recipientId=recipientId, templateId=templateId );

				expect( service.$callLog().$announceInterception.len() ).toBe( 1 );
				expect( service.$callLog().$announceInterception[ 1 ] ).toBe( {
					  state = "onGenerateEmailUnsubscribeLink"
					, interceptData = { templateId=templateId, recipientId=recipientId, recipientType=recipientType }
				} );
			} );

			it( "should return an empty string when no handler action exists", function(){
				var service         = _getService();
				var recipientType   = "websiteUser";
				var expectedHandler = "email.recipientType.websiteUser.getUnsubscribeLink";
				var recipientId     = CreateUUId();
				var templateId      = CreateUUId();

				mockColdboxController.$( "handlerExists" ).$args( expectedHandler ).$results( false );

				expect( service.getUnsubscribeLink( recipientType=recipientType, recipientId=recipientId, templateId=templateId ) ).toBe( "" );
			} );

			it( "should return an empty string when the recipient type does not exist", function(){
				var service         = _getService();
				var recipientType   = CreateUUId();
				var recipientId     = CreateUUId();
				var templateId      = CreateUUId();

				expect( service.getUnsubscribeLink( recipientType=recipientType, recipientId=recipientId, templateId=templateId ) ).toBe( "" );
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
		service.$( "$announceInterception" );

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
			  websiteUser = { feature="websiteUsers", parameters=[ { id="known_as", required=true }, "login_id" ], filterObject="website_user", recipientIdLogProperty="website_user_recipient" }
			, adminUser   = { feature="cms", parameters=[ "display_name", "login_id" ], filterObject="security_user", recipientIdLogProperty="security_user_recipient", gridFields=[ "known_as", "email_address" ] }
			, anonymous   = {}
		};
	}
}