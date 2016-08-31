/**
 * Provides service logic for recording user actions (auditing)
 *
 * @autodoc
 * @singleton
 * @presideService
 */
component displayName="Website user action service" {

// CONSTRUCTOR
	public any function init() {
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
		  required string userId
		, required string action
		, required string type
		,          any    detail = {}
	) {
		return $getPresideObject( "website_user_action" ).insertData({
			  user   = userId
			, action = arguments.action
			, type   = arguments.type
			, detail = SerializeJson( arguments.detail )
			, uri        = cgi.request_url
			, user_ip    = cgi.remote_addr
			, user_agent = cgi.http_user_agent
		});
	}
}