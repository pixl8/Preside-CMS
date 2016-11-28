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
	}

// PRIVATE HELPERS
	private any function _getService( struct configuredProviders=_getDefaultTestProviders() ) {
		var service = createMock( object=new preside.system.services.email.EmailServiceProviderService(
			configuredProviders = arguments.configuredProviders
		) );

		service.$( "$getPresideSetting", "" );

		return service;
	}

	private struct function _getDefaultTestProviders() {
		return {
			  smtp      = {}
			, mailgun   = {}
			, mailchimp = { configForm="blah.blah.mailchimp.blah" }
		};
	}
}