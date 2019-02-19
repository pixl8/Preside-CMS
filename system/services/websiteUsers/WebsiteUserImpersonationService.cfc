/**
 * The website user impersonation service provides methods for setting up and resolving user
 * impersonation, even if from a sub-site with a separate domain.
 *
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

	/**
	 * Sets up an in-memory impersonation record when passed a website user id and target URL. Returns the
	 * appropriate redirect URL with impersonation key appended.
	 *
	 * @userId.hint     ID of the website user to impersonate
	 * @targetUrl.hint  The URL to redirect to upon successful impersonation
	 *
	 */
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

	/**
	 * Looks up an impersonation record, deletes it from memory and returns the original target URL.
	 *
	 * @id.hint  The impersonation ID returned by the create() method.
	 *
	 */
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