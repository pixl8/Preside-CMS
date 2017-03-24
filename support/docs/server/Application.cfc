component {
	this.name = "presidecmsDocumentationLocalServer-" & Hash( GetCurrentTemplatePath() );

	this.cwd     = GetDirectoryFromPath( GetCurrentTemplatePath() );
	this.baseDir = ExpandPath( this.cwd & "../" );

	this.mappings[ "/api"      ] = this.baseDir & "api";
	this.mappings[ "/builders" ] = this.baseDir & "builders";
	this.mappings[ "/docs"     ] = this.baseDir & "docs";

	public boolean function onRequest( required string requestedTemplate ) output=true {
		if ( _isSearchIndexRequest() ) {
			_renderSearchIndex();
		} else if ( _isAssetRequest() ) {
			_renderAsset();
		} else if ( _isImageRequest() ) {
			_renderImage();
		} else {
			_renderPage();
		}

		return true;
	}

// PRIVATE
	private void function _renderPage() {
		var pagePath    = _getPagePathFromRequest();
		var buildRunner = _getBuildRunner();
		var docTree     = buildRunner.getDocTree();
		var page        = docTree.getPageByPath( pagePath );

		if ( IsNull( page ) ) {
			_404();
		}

		WriteOutput( buildRunner.getBuilder( "html" ).renderPage( page, docTree ) );

	}

	private void function _renderAsset() {
		var assetPath = "/builders/html" & _getRequestUri();

		if ( !FileExists( assetPath ) ) {
			_404();
		}

		header name="cache-control" value="no-cache";
		content file=assetPath type=_getMimeTypeForAsset( assetPath );abort;
	}

	private void function _renderImage() {
		var assetPath = "/docs/_images" & _getRequestUri().reReplace( "^/images", "" );

		if ( !FileExists( assetPath ) ) {
			_404();
		}

		header name="cache-control" value="no-cache";
		content file=assetPath type=_getMimeTypeForAsset( assetPath );abort;
	}


	private void function _renderSearchIndex() {
		var buildRunner = _getBuildRunner();
		var docTree = buildRunner.getDocTree();
		var searchIndex = buildRunner.getBuilder( "html" ).renderSearchIndex( docTree );

		header name="cache-control" value="no-cache";
		content type="application/json" reset=true;
		writeOutput( searchIndex );
		abort;
	}

	private string function _getPagePathFromRequest() {
		var path = _getRequestUri();

		path = ReReplace( path, "\.html$", "" );

		if ( path == "/" || path == "/index" ) {
			path = "/home";
		}

 		return path;
	}

	private string function _getRequestUri() {
		return request[ "javax.servlet.forward.request_uri" ] ?: "/";
	}

	private void function _404() {
		content reset="true" type="text/plain";
		header statuscode=404;
		WriteOutput( "404 Not found" );
		abort;
	}

	private boolean function _isSearchIndexRequest() {
		return _getRequestUri() == "/assets/js/searchIndex.json";
	}

	private boolean function _isAssetRequest() {
		return _getRequestUri().startsWith( "/assets" );
	}

	private boolean function _isImageRequest() {
		return _getRequestUri().startsWith( "/images" );
	}

	private string function _getMimeTypeForAsset( required string filePath ) {
		var extension = ListLast( filePath, "." );

		switch( extension ){
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

	private any function _getBuildRunner() {
		var appKey    = application.buildRunnerKey ?: "";
		var newAppKey = _calculateBuildRunnerAppKey()

		if ( appKey != newAppKey || !application.keyExists( appKey ) ) {
			application.delete( appKey );
			application[ newAppKey ] = new api.build.BuildRunner();
			application.buildRunnerKey = newAppKey;
		}

		return application[ newAppKey ];

	}

	private string function _calculateBuildRunnerAppKey() {
		var filesEtc = DirectoryList( "/docs", true, "query" );
		var sig      = Hash( SerializeJson( filesEtc ) );

		return "buildrunner" & sig;
	}
}