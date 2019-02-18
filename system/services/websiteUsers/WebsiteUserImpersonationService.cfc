/**
 * @singleton
 * @presideservice
 * @autodoc
 */
component displayName="Website user impersonation service" {

// constructor
	/**
	 * @websiteLoginService.inject   websiteLoginService
	 */
	public any function init( required any websiteloginService ) {
		_setWebsiteLoginService( arguments.websiteLoginService );
		variables.impersonations = {};

		return this;
	}

// public api methods
	public string function create( required string userId, required string targetUrl ) {
		var impersonationId  = _addImpersonation( argumentCollection=arguments );
		var impersonationUrl = arguments.targetUrl;

		if ( find( "?", impersonationUrl ) ) {
			impersonationUrl &= "&impersonate=" & impersonationId;
		} else {
			impersonationUrl &= "?impersonate=" & impersonationId;
		}

		return impersonationUrl;
	}

	public string function resolve( required string id ) {
		var impersonation = _getImpersonation( arguments.id );

		if ( impersonation.isEmpty() ) {
			return "";
		}

		_getWebsiteLoginService().impersonate( impersonation.userId );
		_removeImpersonation( arguments.id );

		return impersonation.targetUrl;
	}


// private methods
	private string function _addImpersonation( required string userId, required string targetUrl ) {
		var impersonationId = createUUID();

		variables.impersonations[ impersonationId ] = {
			  userId    = arguments.userId
			, targetUrl = arguments.targetUrl
		};

		return impersonationId;
	}

	private struct function _getImpersonation( required string id ) {
		return duplicate( variables.impersonations[ id ] ?: {} );
	}

	private void function _removeImpersonation( required string id ) {
		variables.impersonations.delete( id );
	}

// private accessors
	private any function _getWebsiteLoginService() {
		return _websiteLoginService;
	}
	private void function _setWebsiteLoginService( required any websiteLoginService ) {
		_websiteLoginService = arguments.websiteLoginService;
	}
}