component output=false {

	function download( event, rc, prc ) output=false {
		var assetFile = ExpandPath( rc.staticAssetPath ?: "" );

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
	private boolean function _fileExists( required string fullPath ) output=false {
		var rootAllowedDirectory = ExpandPath( "/preside/system/assets" );

		if ( !fullPath.startsWith( rootAllowedDirectory ) || fullPath contains ".." ) {
			return false;
		}

		return FileExists( arguments.fullPath );
	}

	private string function _getEtag( required string fullPath ) output=false {
		return Hash( SerializeJson( GetFileInfo( arguments.fullPath ) ) );
	}

	private string function _doBrowserEtagLookup( required string etag ) output=false {
		if ( ( cgi.http_if_none_match ?: "" ) == arguments.etag ) {
			content reset=true;header statuscode=304 statustext="Not Modified";abort;
		}
	}

	private string function _getMimeType( assetFile ) output=false {
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
}