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
		return ReFindNoCase( "^/file/(.*?)/", arguments.path );
	}

	public void function translate( required string path, required any event ) output=false {
		var storagePath     = ToString( ToBinary( ReReplace( arguments.path, "^/file/(.*?)/.*$", "\1" ) ) );
		var storageProvider = ListFirst( storagePath, "/" );
		var filename        = ListLen( storagePath, "|" ) > 1 ? ListRest( storagePath, "|" ) : ListLast( storagePath, "/" );
		var derivativeId = "";
		var urlParam     = "";

		event.setValue( "storageProvider", storageProvider );
		event.setValue( "filename"       , filename );
		event.setValue( "storagePath"    , "/" & ListFirst( ListRest( storagePath, "/" ), "|" ) );

		event.setValue( _getEventName(), "core.FileDownload" );

		if ( ReFind( "^/file/.*?/(.*?)/.*$", arguments.path ) ) {
			derivativeId = UrlDecode( ReReplace( arguments.path, "^/file/.*?/(.*?)/.*$", "\1" ) );
			event.setValue( "derivativeId", derivativeId );
		}
	}

	public boolean function reverseMatch( required struct buildArgs, required any event ) output=false {
		return Len( Trim( buildArgs.fileStoragePath ?: "" ) ) && Len( Trim( buildArgs.fileStorageProvider ?: "" ) );
	}

	public string function build( required struct buildArgs, required any event ) output=false {
		var path = '/' & buildArgs.fileStorageProvider & buildArgs.fileStoragePath;

		if ( Len( Trim( buildArgs.filename ?: "" ) ) ) {
			path &= "|" & buildArgs.filename;
		}

		var link = "/file/#ToBase64( path )#/";

		return event.getSiteUrl( includeLanguageSlug=false ) & link;
	}

// private getters and setters
	private string function _getEventName() output=false {
		return _eventName;
	}
	private void function _setEventName( required string eventName ) output=false {
		_eventName = arguments.eventName;
	}
}