component implements="iRouteHandler" output=false singleton=true {

// constructor
	/**
	 * @eventName.inject coldbox:setting:eventName
	 */
	public any function init( required string eventName ) output=false {
		_setEventName( arguments.eventName );

		return this;
	}

// route handler methods
	public boolean function match( required string path, required any event ) output=false {
		return ReFindNoCase( "^/asset/(.*?)/", arguments.path );
	}

	public void function translate( required string path, required any event ) output=false {
		var assetId      = UrlDecode( ReReplace( arguments.path, "^/asset/(.*?)/.*$", "\1" ) );
		var isTempAsset  = Left( assetId, 1 ) eq "_";
		var derivativeId = "";
		var urlParam     = "";

		event.setValue( "assetId", ReReplace( assetId, "^_", "" ) );

		event.setValue( _getEventName(), "core.AssetDownload." & ( isTempAsset ? "tempFile" : "asset" ) );

		if ( ReFind( "^/asset/.*?/(.*?)/.*$", arguments.path ) ) {
			derivativeId = UrlDecode( ReReplace( arguments.path, "^/asset/.*?/(.*?)/.*$", "\1" ) );
			event.setValue( "derivativeId", derivativeId );
		}
	}

	public boolean function reverseMatch( required struct buildArgs, required any event ) output=false {
		return Len( Trim( buildArgs.assetId ?: "" ) );
	}

	public string function build( required struct buildArgs, required any event ) output=false {
		var link = "/asset/#UrlEncodedFormat( buildArgs.assetId ?: '' )#/";

		if ( Len( Trim( buildArgs.derivative ?: "" ) ) ) {
			link &= "#UrlEncodedFormat( buildArgs.derivative )#/";
		}

		if ( buildArgs.isTemporaryAsset ?: false ) {
			link = ReReplace( link, "^/asset/", "/asset/_" );
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
}