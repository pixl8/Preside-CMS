/**
 * @singleton
 * @implements iRouteHandler
 */
component  {

// constructor
	/**
	 * @eventName.inject coldbox:setting:eventName
	 * @restPath.inject  coldbox:setting:rest.path
	 */
	public any function init( required string eventName, required string restPath ) {
		_setEventName( arguments.eventName );
		_setRestPath( arguments.restPath );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) {
		var restPath = _getRestPath();

		return ReFindNoCase( "^" & restPath, arguments.path );
	}

	public void function translate( required string path, required any event ) {
		var restPath = _getRestPath();
		var uri      = Replace( arguments.path, restPath, "" );

		event.setValue( "restUri", uri );
		event.setValue( _getEventName(), "core.rest.processRequest" );
	}

	public boolean function reverseMatch( required struct buildArgs, required any event ) {
		return StructKeyExists( arguments.buildArgs, "linkTo" );
	}

	public string function build( required struct buildArgs, required any event ) {
		var link = "";

		if ( Len( Trim( buildArgs.queryString ?: "" ) ) ) {
			link &= "?" & buildArgs.queryString;
		}

		return event.getSiteUrl() & link;
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
}