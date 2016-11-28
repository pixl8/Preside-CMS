component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "listProviders()", function(){
			it( "should return a list of configured service providers, with translated titles, descriptions and icons", function(){
				var service = _getService();
				var providers = _getDefaultTestProviders();
				var expected  = [];

				for( var providerId in providers ) {
					var provider = {
						  id          = providerId
						, title       = providerId & CreateUUId()
						, description = providerId & CreateUUId()
						, iconClass   = providerId & CreateUUId()
					};

					expected.append( provider );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:title"      , defaultValue=providerId ).$results( provider.title       );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:description", defaultValue=""         ).$results( provider.description );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:iconClass"  , defaultValue=""         ).$results( provider.iconClass   );
				}

				expected.sort( function( a, b ){
					return a.title > b.title ? 1 : -1;
				} );


				expect( service.listProviders() ).toBe( expected ); ;
			} );

			it( "should exclude services when they have been disabled through preside system settings", function(){
				var service   = _getService();
				var providers = _getDefaultTestProviders();
				var expected  = [];
				var excluded  = "mailgun,smtp";

				service.$( "$getPresideSetting" ).$args( "email.serviceProviders", "disabledProviders" ).$results( excluded );

				for( var providerId in providers ) {
					if ( ListFindNoCase( excluded, providerId ) ) {
						continue;
					}

					var provider = {
						  id          = providerId
						, title       = providerId & CreateUUId()
						, description = providerId & CreateUUId()
						, iconClass   = providerId & CreateUUId()
					};

					expected.append( provider );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:title"      , defaultValue=providerId ).$results( provider.title       );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:description", defaultValue=""         ).$results( provider.description );
					service.$( "$translateResource" ).$args( uri="email.serviceProvider.#providerId#:iconClass"  , defaultValue=""         ).$results( provider.iconClass   );
				}

				expected.sort( function( a, b ){
					return a.title > b.title ? 1 : -1;
				} );


				expect( service.listProviders() ).toBe( expected ); ;
			} );
		} );

		describe( "getDefaultProvider()", function(){
			it( "should return the configured default provider", function(){
				var service = _getService();
				var defaultProvider = "smtp";

				service.$( "$getPresideSetting" ).$args( "email.serviceProviders", "defaultProvider" ).$results( defaultProvider );

				expect( service.getDefaultProvider() ).toBe( defaultProvider );
			} );

			it( "should return the first in the list of providers when no default set in settings", function(){
				var service = _getService();
				var defaultProvider = CreateUUId();

				service.$( "$getPresideSetting" ).$args( "email.serviceProviders", "defaultProvider" ).$results( "" );
				service.$( "listProviders", [ { id=defaultProvider } ] )

				expect( service.getDefaultProvider() ).toBe( defaultProvider );
			} );

			it( "should return an empty string when no default configured and no providers listed", function(){
				var service = _getService();

				service.$( "$getPresideSetting" ).$args( "email.serviceProviders", "defaultProvider" ).$results( "" );
				service.$( "listProviders", [] )

				expect( service.getDefaultProvider() ).toBe( "" );
			} );
		} );

		describe( "getProviderConfigFormName()", function(){
			it( "should return the configured config form name for the provider", function(){
				var service   = _getService();
				var providers = _getDefaultTestProviders();
				var provider  = "mailchimp";

				expect( service.getProviderConfigFormName( provider ) ).toBe( providers[ provider ].configForm );
			} );

			it( "should return a convention based form name when no specific form configured", function(){
				var service   = _getService();
				var provider  = "smtp";

				expect( service.getProviderConfigFormName( provider ) ).toBe( "email.serviceProvider.smtp" );
			} );
		} );

		describe( "getProviderSendAction()", function(){
			it( "should return the configured send action for the provider", function(){
				var service   = _getService();
				var providers = _getDefaultTestProviders();
				var provider  = "mailgun";

				expect( service.getProviderSendAction( provider ) ).toBe( providers[ provider ].sendAction );
			} );

			it( "should return a convention based action when no specific action configured", function(){
				var service   = _getService();
				var provider  = "smtp";

				expect( service.getProviderSendAction( provider ) ).toBe( "email.serviceProvider.smtp.send" );
			} );
		} );

		describe( "isProviderEnabled()", function(){
			it( "should return false when the provider is in the list of configured disabled providers", function(){
				var service   = _getService();
				var excluded  = "mailgun,smtp";

				service.$( "$getPresideSetting" ).$args( "email.serviceProviders", "disabledProviders" ).$results( excluded );

				expect( service.isProviderEnabled( "smtp" ) ).toBe( false );
			} );

			it( "should return false when the provider does not exist", function(){
				var service   = _getService();

				expect( service.isProviderEnabled( CreateUUId() ) ).toBe( false );
			} );

			it( "should return true when the provider is not in the disabled providers list + exists in the configured providers struct", function(){
				var service   = _getService();
				var excluded  = "mailgun,mailchimp";

				service.$( "$getPresideSetting" ).$args( "email.serviceProviders", "disabledProviders" ).$results( excluded );

				expect( service.isProviderEnabled( "smtp" ) ).toBe( true );
			} );
		} );

		describe( "sendWithProvider()", function(){
			it( "should call the providers configured send action passing through any passed args and saved provider config and returning the boolean result", function(){
				var service       = _getService();
				var result        = true;
				var providers     = _getDefaultTestProviders();
				var provider      = "mailgun";
				var sendAction    = CreateUUId() & ".send";
				var dummyArgs     = { test=CreateUUId(), fu="bar" };
				var dummySettings = { server=CreateUUId(), fu="bar", password=CreateUUId() };

				service.$( "$getPresideCategorySettings" ).$args( "email.serviceProvider.#provider#" ).$results( dummySettings );
				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockColdbox.$( "runEvent" ).$args(
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs=dummyArgs, settings=dummySettings }
				).$results( result );

				expect( service.sendWithProvider( provider, dummyArgs ) ).toBe( result );

				expect( mockColdbox.$callLog().runEvent.len() ).toBe( 1 );
				expect( mockColdbox.$callLog().runEvent[ 1 ] ).toBe( {
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs=dummyArgs, settings=dummySettings }
				} );
			} );

			it( "should return false when the given send event returns false", function(){
				var service       = _getService();
				var result        = false;
				var provider      = "mailgun";
				var sendAction    = CreateUUId() & ".send";
				var dummyArgs     = { test=CreateUUId(), fu="bar" };
				var dummySettings = { what="ever" };

				service.$( "$getPresideCategorySettings" ).$args( "email.serviceProvider.#provider#" ).$results( dummySettings );

				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockColdbox.$( "runEvent" ).$args(
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs=dummyArgs, settings=dummySettings  }
				).$results( result );

				expect( service.sendWithProvider( provider, dummyArgs ) ).toBe( result );
			} );

			it( "should return false when the send action throws an error", function(){
				var service   = _getService();
				var result    = false;
				var provider  = "mailgun";
				var sendAction = CreateUUId() & ".send";

				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockColdbox.$( method="runEvent", throwException=true, throwType="blah.blah", throwMessage="Blah blah blah" );
				service.$( "$raiseError" );

				expect( service.sendWithProvider( provider, {} ) ).toBe( false );
				expect( service.$callLog().$raiseError.len() ).toBe( 1 );
			} );

			it( "should raise an informative error when no send action handler exists", function(){
				var service     = _getService();
				var provider    = "mailgun";
				var sendAction  = CreateUUId() & ".send";
				var errorThrown = false;


				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				mockColdbox.$( "handlerExists" ).$args( sendAction ).$results( false );

				try {
					service.sendWithProvider( provider, {} );
				} catch ( "preside.emailservice.provider.missing.send.action" e ) {
					expect( e.message ).toBe( "The email service provider, [#provider#], has not implemented a send action handler. Missing handler: [#sendAction#]." );
					errorThrown = true;
				}

				expect( errorThrown ).toBe( true );
			} );

			it( "should return false and raise a silent error when the send action does not return a boolean value", function(){
				var service   = _getService();
				var provider  = "mailgun";
				var sendAction = CreateUUId() & ".send";
				var dummyArgs = { test=CreateUUId(), fu="bar" };

				service.$( "getProviderSendAction" ).$args( provider ).$results( sendAction );
				service.$( "$getPresideCategorySettings" ).$args( "email.serviceProvider.#provider#" ).$results( {} );
				mockColdbox.$( "runEvent" ).$args(
					  event          = sendAction
					, private        = true
					, prePostExempt  = true
					, eventArguments = { sendArgs=dummyArgs, settings={} }
				).$results( {} );
				service.$( "$raiseError" );

				expect( service.sendWithProvider( provider, dummyArgs ) ).toBe( false );
				expect( service.$callLog().$raiseError.len() ).toBe( 1 );

				var errorRaised = service.$callLog().$raiseError[ 1 ][ 1 ];

				expect( errorRaised.type    ?: "" ).toBe( "preside.emailservice.provider.invalid.send.action.return.value" );
				expect( errorRaised.message ?: "" ).toBe( "The email service provider send action, [#sendAction#], for the provider, [#provider#], did not return a boolean value to indicate success/failure of email sending." );
				expect( errorRaised.detail  ?: "" ).toBe( "The system has return false to indicate a failure and has logged this error silently as a warning." );
			} );
		} );

		describe( "saveSettings()", function(){
			it( "should proxy to the preside system configuration service, calculating the category name by convention", function(){
				var service           = _getService();
				var mockConfigService = createEmptyMock( "preside.system.services.configuration.SystemConfigurationService" );
				var settings          = StructNew( "linked" );
				var site              = CreateUUId();
				var provider          = "mailgun";
				var settingsCategory  = "email.serviceProvider.#provider#";

				settings.test = "setting";
				settings.blah = CreateUUId();

				service.$( "$getSystemConfigurationService", mockConfigService );
				for( var settingid in settings ) {
					mockConfigService.$( "saveSetting" ).$args(
						  category = settingsCategory
						, setting  = settingId
						, value    = settings[ settingId ]
						, siteId   = site
					).$results( 1 );
				}

				service.saveSettings(
					  provider = provider
					, settings = settings
					, site     = site
				);

				expect( mockConfigService.$callLog().saveSetting.len() ).toBe( settings.count() );
				var i=0;
				for( var settingid in settings ) {
					expect( mockConfigService.$callLog().saveSetting[ ++i ] ).toBe( {
						  category = settingsCategory
						, setting  = settingId
						, value    = settings[ settingId ]
						, siteId   = site
					} );
				}
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService( struct configuredProviders=_getDefaultTestProviders() ) {
		var service = createMock( object=new preside.system.services.email.EmailServiceProviderService(
			configuredProviders = arguments.configuredProviders
		) );

		mockColdbox = createEmptyMock( "preside.system.coldboxModifications.Controller" );

		service.$( "$getPresideSetting", "" );
		service.$( "$getPresideCategorySettings", {} );
		service.$( "$getColdbox", mockColdbox );
		mockColdbox.$( "handlerExists", true );

		return service;
	}

	private struct function _getDefaultTestProviders() {
		return {
			  smtp      = {}
			, mailgun   = { sendAction="whatev.send" }
			, mailchimp = { configForm="blah.blah.mailchimp.blah" }
		};
	}
}