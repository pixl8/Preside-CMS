component {
	property name="i18n"       inject="i18n";
	property name="appMapping" inject="coldbox:setting:appMapping";

	function download( event, rc, prc ) {
		var staticAssetPath = _translatePath( rc.staticAssetPath ?: "" );
		var assetFile       = ExpandPath( staticAssetPath );

		if ( rc.staticAssetPath.reFindNoCase( "^/preside/system/assets/_dynamic/i18nBundle\.js" ) ) {
			_serveI18nBundle( argumentCollection = arguments );
		}

		if ( !_fileExists( assetFile ) ) {
			event.notFound();
		}

		var etag = _getEtag( assetFile );

		_doBrowserEtagLookup( etag );

		header name="cache-control" value="max-age=31536000";
		header name="etag" value=etag;
		content file="#assetFile#" type=_getMimeType( assetFile );abort;
	}

// PRIVATE HELPERS
	private boolean function _fileExists( required string fullPath ) {
		var rootAllowedDirectory = ExpandPath( "/preside/system/assets" );
		var extensionsDirectory  = ExpandPath( "/#appMapping#/extensions/" );

		if ( ( fullPath.left( rootAllowedDirectory.len() ) != rootAllowedDirectory && fullPath.left( extensionsDirectory.len() ) != extensionsDirectory ) || fullPath contains ".." ) {
			return false;
		}

		return FileExists( arguments.fullPath );
	}

	private string function _getEtag( required string fullPath ) {
		return Left( LCase( Hash( SerializeJson( GetFileInfo( arguments.fullPath ) ) ) ), 8 );
	}

	private string function _doBrowserEtagLookup( required string etag ) {
		if ( ( cgi.http_if_none_match ?: "" ) == arguments.etag ) {
			content reset=true;header statuscode=304 statustext="Not Modified";abort;
		}
	}

	private string function _getMimeType( assetFile ) {
		switch( ListLast( arguments.assetFile, "." ) ){
			case "css": return "text/css";
			case "js" : return "application/javascript";
			case "jpe": case "jpeg": case "jpg": return "image/jpg";
			case "png": return "image/png";
			case "gif": return "image/gif";
			case "svg": return "image/svg+xml";
			case "woff": return "font/x-woff";
			case "eot": return "application/vnd.ms-fontobject";
			case "otf": return "font/otf";
			case "ttf": return "application/octet-stream";
		}

		return "application/octet-stream";
	}

	private void function _serveI18nBundle( event, rc, prc ) {
		var locale = getFwLocale();
		var js     = i18n.getI18nJsForAdmin();
		var etag   = Left( LCase( Hash( js ) ), 8 );

		_doBrowserEtagLookup( etag );

		setting showdebugoutput=false;

		header name="cache-control" value="max-age=#( 2400 )#"; // cache for 20 min
		header name="etag" value=etag;
		content reset=true type="application/javascript";WriteOutput(js);abort;
	}

	private string function _translatePath( required string path ) {
		return ReReplace( arguments.path, "^/preside/system/assets/extension/", "/#appMapping#/extensions/" );
	}
}