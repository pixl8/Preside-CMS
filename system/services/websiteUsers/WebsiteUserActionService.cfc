/**
 * Provides service logic for recording user actions (auditing)
 *
 * @autodoc
 * @singleton
 * @presideService
 */
component displayName="Website user action service" {

// CONSTRUCTOR
	/**
	 * @websiteVisitorService.inject websiteVisitorService
	 * @sessionStorage.inject        coldbox:plugin:sessionStorage
	 */
	public any function init(
		  required any websiteVisitorService
		, required any sessionStorage
	) {
		_setWebsiteVisitorService( arguments.websiteVisitorService );
		_setSessionStorage( arguments.sessionStorage );

		return this;
	}

// PUBLIC API
	/**
	 * Records an action for the given user
	 *
	 * @autodoc
	 * @userId.hint ID of the user to record the action for
	 * @action.hint ID of the action to record, e.g. 'logout'
	 * @type.hint   Type of the action to record, e.g. 'login'
	 * @detail.hint Additional detail to record with the action, will be serialized to JSON when saved in the DB
	 */
	public string function recordAction(
		  required string action
		, required string type
		,          string userId     = ""
		,          string identifier = ""
		,          any    detail     = {}
	) {
		var data = {
			  action     = arguments.action
			, type       = arguments.type
			, detail     = SerializeJson( arguments.detail )
			, identifier = arguments.identifier
			, session_id = _getSessionId()
			, uri        = cgi.request_url
			, user_ip    = cgi.remote_addr
			, user_agent = cgi.http_user_agent
		};

		if ( Len( Trim( arguments.userId ) ) ) {
			data.user = arguments.userId;
		} else {
			data.visitor = _getWebsiteVisitorService().getVisitorId();
		}

		return $getPresideObject( "website_user_action" ).insertData( data );
	}

	/**
	 * Transfers all of the current visitor's actions
	 * for this session to the given user
	 *
	 * @autodoc
	 * @userId.hint ID of the user who will take the visitor's actions
	 *
	 */
	public numeric function promoteVisitorActionsToUserActions( required string userId ) {
		var sessionId = _getSessionId();
		var visitorId = _getWebsiteVisitorService().getVisitorId();

		return $getPresideObject( "website_user_action" ).updateData(
			  filter = { "website_user_action.session_id"=sessionId, "website_user_action.visitor"=visitorId }
			, data   = { visitor="", user=arguments.userId }
		);
	}

// PRIVATE HELPERS
	private string function _getSessionId() {
		var sessionStorage = _getSessionStorage();
		var sessionId      = sessionStorage.getVar( name="_presideSessionId", default="" );

		if ( !Len( Trim( sessionId ) ) ) {
			sessionId = LCase( CreateUUId() );
			sessionStorage.setVar( name="_presideSessionId", value=sessionId );
		}

		return sessionId;
	}

// GETTERS AND SETTERS
	private any function _getWebsiteVisitorService() {
		return _websiteVisitorService;
	}
	private void function _setWebsiteVisitorService( required any websiteVisitorService ) {
		_websiteVisitorService = arguments.websiteVisitorService;
	}

	private any function _getSessionStorage() {
		return _sessionStorage;
	}
	private void function _setSessionStorage( required any sessionStorage ) {
		_sessionStorage = arguments.sessionStorage;
	}
}