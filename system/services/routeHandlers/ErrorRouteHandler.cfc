component implements="iRouteHandler" output=false singleton=true {

// constructor
	/**
	 * @eventName.inject       coldbox:setting:eventName
	 */
	public any function init( required string eventName ) output=false {
		_setEventName( arguments.eventName );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) output=false {
		return ReFindNoCase( "^/404.html$", arguments.path );
	}

	public void function translate( required string path, required any event ) output=false {
		var prc        = event.getCollection( private=true );

		prc.statusCode = 404;

		event.setValue( _getEventName(), "general.notFound" );
	}

	public boolean function reverseMatch( required struct buildArgs, required any event ) output=false {
		return false; // cannot build an error link, incoming only
	}

	public string function build( required struct buildArgs, required any event ) output=false {
		return "/"; // cannot build an error link, incoming only
	}

// private getters and setters
	private string function _getEventName() output=false {
		return _eventName;
	}
	private void function _setEventName( required string eventName ) output=false {
		_eventName = arguments.eventName;
	}
}