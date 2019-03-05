/**
 * The website user impersonation service provides methods for setting up and resolving user
 * impersonation, even if from a sub-site with a separate domain.
 * \n
 * Introduced in *10.10.39*.
 *
 * @singleton
 * @presideservice
 * @autodoc
 */
component displayName="Website user impersonation service" {

// constructor
	/**
	 * @websiteLoginService.inject   websiteLoginService
	 * @cacheProvider.inject         cachebox:ImpersonationCache
	 */
	public any function init(
		  required any websiteloginService
		, required any cacheProvider
	) {
		_setWebsiteLoginService( arguments.websiteLoginService );
		_setCacheProvider( arguments.cacheProvider );
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
	 * @autodoc         true
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
	 * @autodoc  true
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

		_getCacheProvider().set(
			  objectKey = impersonationId
			, object    = {
				  userId    = arguments.userId
				, targetUrl = arguments.targetUrl
			  }
		);

		return impersonationId;
	}

	private struct function _getImpersonation( required string id ) {
		var impersonation = _getCacheProvider().get( arguments.id );

		if ( isNull( local.impersonation ) ) {
			return {};
		}

		return impersonation;
	}

	private void function _removeImpersonation( required string id ) {
		_getCacheProvider().clear( arguments.id );
	}

// private accessors
	private any function _getWebsiteLoginService() {
		return _websiteLoginService;
	}
	private void function _setWebsiteLoginService( required any websiteLoginService ) {
		_websiteLoginService = arguments.websiteLoginService;
	}

	private any function _getCacheProvider() {
		return _cacheProvider;
	}
	private void function _setCacheProvider( required any cacheProvider ) {
		_cacheProvider = arguments.cacheProvider;
	}
}