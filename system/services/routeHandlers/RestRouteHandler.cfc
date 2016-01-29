/**
 * @singleton
 * @implements iRouteHandler
 */
component  {

// constructor
	/**
	 * @eventName.inject           coldbox:setting:eventName
	 * @restPath.inject            coldbox:setting:rest.path
	 * @presideRestService.inject  delayedInjector:presideRestService
	 */
	public any function init( required string eventName, required string restPath, required any presideRestService ) {
		_setEventName( arguments.eventName );
		_setRestPath( arguments.restPath );
		_setPresideRestService( arguments.presideRestService );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) {
		var restPath = _getRestPath();

		return ReFindNoCase( "^" & restPath, arguments.path ) && _getPresideRestService().getApiForUri( Replace( arguments.path, restPath, "" ) ).len();
	}

	public void function translate( required string path, required any event ) {
		var restPath = _getRestPath();
		var uri      = Replace( arguments.path, restPath, "" );

		event.setValue( "restUri", uri );
		event.setValue( _getEventName(), "core.rest.request" );
	}

	public boolean function reverseMatch( required struct buildArgs, required any event ) {
		return false;
	}

	public string function build( required struct buildArgs, required any event ) {
		return "";
	}

// private getters and setters
	private string function _getEventName() {
		return _eventName;
	}
	private void function _setEventName( required string eventName ) {
		_eventName = arguments.eventName;
	}

	private string function _getRestPath() {
		return _restPath;
	}
	private void function _setRestPath( required string restPath ) {
		_restPath = arguments.restPath;
	}

	private any function _getPresideRestService() {
		return _presideRestService;
	}
	private void function _setPresideRestService( required any presideRestService ) {
		_presideRestService = arguments.presideRestService;
	}
}