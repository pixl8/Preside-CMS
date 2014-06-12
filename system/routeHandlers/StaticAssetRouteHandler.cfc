component implements="iRouteHandler" output=false {

// constructor
	public any function init( required string eventName ) output=false {
		_setEventName( arguments.eventName );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) output=false {
		return ReFindNoCase( "^/preside/system/assets/(.*?)/", arguments.path ) && !ReFind( "\.\.", arguments.path );
	}

	public void function translate( required string path, required any event ) output=false {
		event.setValue( "staticAssetPath", arguments.path );
		event.setValue( _getEventName(), "admin.StaticAssetDownload.download" );
	}

	public boolean function reverseMatch( required struct buildArgs ) output=false {
		return Len( Trim( buildArgs.systemStaticAsset ?: "" ) );
	}

	public string function build( required struct buildArgs ) output=false {
		var path = buildArgs.systemStaticAsset ?: "";

		if ( !ReFind( "^/", path ) ) {
			path = "/" & path;
		}

		return "/preside/system/assets" & path;
	}

// private getters and setters
	private string function _getEventName() output=false {
		return _eventName;
	}
	private void function _setEventName( required string eventName ) output=false {
		_eventName = arguments.eventName;
	}
}