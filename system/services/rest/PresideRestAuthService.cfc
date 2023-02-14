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
	public void function authenticate(
		  required string provider
		, required any    restRequest
		, required any    restResponse
	) {
		var configuredProviders = _getConfiguredProviders();
		var handlerAction       = configuredProviders[ arguments.provider ].authenticationHandler ?: "rest.auth.#arguments.provider#.authenticate";
		var providerFeature     = configuredProviders[ arguments.provider ].feature ?: "";
		var coldbox             = $getColdbox();

		if ( providerFeature.len() && !$isFeatureEnabled( providerFeature ) ) {
			_failRequest( restRequest, restResponse, "Authentication provider [#provider#] is not enabled." );
			return;
		}

		if ( !coldbox.handlerExists( handlerAction ) ) {
			_failRequest( restRequest, restResponse, "Authentication provider [#provider#] is missing or badly configured." );
			return;
		}

		var userId = coldbox.runEvent(
			  event         = handlerAction
			, private       = true
			, prePostExempt = true
			, eventArguments = { restRequest=restRequest, restResponse=restResponse }
		);

		if ( IsSimpleValue( userId ?: {} ) && userId.len() ) {
			restRequest.setUser( userId );
			return;
		}

		_failRequest( restRequest, restResponse, "Not authorized" );
	}

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

	public string function getUserIdByToken( required string token ) {
		var record = $getPresideObject( "rest_user" ).selectData(
			  filter       = { access_token=arguments.token }
			, selectFields = [ "id" ]
		);

		return record.id ?: "";
	}

	public boolean function userHasAccessToApi( required string userId, required string api ) {
		return $getPresideObject( "rest_user_api_access" ).dataExists(
			filter = { rest_user=userId, api=api }
		);
	}

// PRIVATE HELPERS
	private void function _failRequest(
		  required any    restRequest
		, required any    restResponse
		, required string defaultStatusText
	) {
		var statusText = restResponse.getStatusText().len() ? restResponse.getStatusText() : arguments.defaultStatusText;

		restRequest.finish();
		if ( restResponse.getStatusCode() == 200 ) {
			restResponse.setStatusCode( 401 );
		}

		restResponse.setStatusText( statusText );
		restResponse.setError(
			  errorCode = 401
			, title     = "Authorization failed"
			, type      = "rest.authorization.failed"
			, message   = statusText
		);
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredProviders() {
		return _configuredProviders;
	}
	private void function _setConfiguredProviders( required struct configuredProviders ) {
		_configuredProviders = arguments.configuredProviders;
	}

}
