component implements="iRouteHandler" output=false singleton=true {

// constructor
	/**
	 * @eventName.inject  coldbox:setting:eventName
	 * @controller.inject coldbox
	 */
	public any function init( required string eventName, required any controller ) output=false {
		_setEventName( arguments.eventName );
		_setController( arguments.controller );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) output=false {
		return ReFind( "./$", arguments.path );
	}

	public void function translate( required string path, required any event ) output=false {
		var site          = event.getSite();
		var pathMinusSite = arguments.path;

		if ( Len( site.path ?: "" ) > 1 ) {
			pathMinusSite = Right( pathMinusSite, Len( pathMinusSite ) - Len( site.path ) );
			if ( Left( pathMinusSite, 1 ) != "/" ) {
				pathMinusSite = "/" & pathMinusSite;
			}
		}
		var translated = ReReplace( pathMinusSite, "^/", "" );
		    translated = Replace( translated, "/$", "" );
		    translated = ListChangeDelims( translated, ".", "/" );

		if ( !_getController().viewletExists( translated ) && _getController().viewletExists( translated & ".index" ) ) {
			translated &= ".index";
		}

		event.setValue( _getEventName(), translated );
	}

	public boolean function reverseMatch( required struct buildArgs, required any event ) output=false {
		return StructKeyExists( arguments.buildArgs, "linkTo" );
	}

	public string function build( required struct buildArgs, required any event ) output=false {
		var link = "/" & Replace( arguments.buildArgs.linkTo ?: "", ".", "/", "all" ) & "/";

		link = ReReplaceNoCase( link, "index/$", "" );

		if ( Len( Trim( buildArgs.queryString ?: "" ) ) ) {
			link &= "?" & buildArgs.queryString;
		}

		return event.getSiteUrl() & link;
	}

// private getters and setters
	private string function _getEventName() output=false {
		return _eventName;
	}
	private void function _setEventName( required string eventName ) output=false {
		_eventName = arguments.eventName;
	}

	private any function _getController() output=false {
		return _controller;
	}
	private void function _setController( required any Ccntroller ) output=false {
		_controller = arguments.Ccntroller;
	}
}