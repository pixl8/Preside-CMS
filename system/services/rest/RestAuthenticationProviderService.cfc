/**
 * Service for managing multiple authentication providers
 * and authenticating requests
 *
 * @singleton
 * @presideService
 */
component {

// CONSTRUCTOR
	/**
	 * @configuredProviders.inject coldbox:setting:rest.authProviders
	 *
	 */
	public any function init( required struct configuredProviders ) {
		_setConfiguredProviders( arguments.configuredProviders );

		return this;
	}

// PUBLIC API METHODS
	public array function listProviders() {
		var configured = _getConfiguredProviders();
		var providers  = [];

		for( var providerId in configured ) {
			var provider = Duplicate( configured[ providerId ] );

			if ( !Len( provider.feature ?: "" ) || $isFeatureEnabled( provider.feature ) ) {
				providers.append({
					  id                    = providerId
					, authenticationHandler = provider.authenticationHandler ?: "rest.auth.#providerId#.authenticate"
					, title                 = $translateResource( uri="test.auth.#providerId#:title"      , defaultValue=providerId )
					, description           = $translateResource( uri="test.auth.#providerId#:description", defaultValue=""         )
					, iconClass             = $translateResource( uri="test.auth.#providerId#:iconClass"  , defaultValue="fa-users" )
				});
			}
		}

		providers = providers.sort( function( a, b ){
			a.title > b.title ? 1 : -1;
		} );

		return providers;
	}

	public string function authenticate(
		  required string provider
		, required any    restRequest
		, required any    restResponse
	) {
		var configuredProviders = _getConfiguredProviders();
		var handlerAction       = configuredProviders[ arguments.provider ].authenticationHandler ?: "rest.auth.#arguments.provider#.authenticate";
		var providerFeature     = configuredProviders[ arguments.provider ].feature ?: "";
		var coldbox             = $getColdbox();

		if ( providerFeature.len() && !$isFeatureEnabled( providerFeature ) ) {
			return "Authentication provider [#provider#] is not enabled.";
		}

		if ( !coldbox.handlerExists( handlerAction ) ) {
			return "Authentication provider [#provider#] is missing or badly configured.";
		}

		var result = coldbox.runEvent(
			  event         = handlerAction
			, private       = true
			, prePostExempt = true
			, eventArguments = { restRequest=restRequest, restResponse=restResponse }
		);

		return IsSimpleValue( result ) ? result : "";
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredProviders() {
		return _configuredProviders;
	}
	private void function _setConfiguredProviders( required struct configuredProviders ) {
		_configuredProviders = arguments.configuredProviders;
	}

}
