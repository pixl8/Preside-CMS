<cfscript>
	setUniqueUrls( false );
	setExtensionDetection( false );
	setBaseUrl( "/" );

	function pathInfoProvider( event ) output=false {
		var requestData = GetHttpRequestData();
		var uri         = ListFirst( ( requestData.headers['X-Original-URL'] ?: cgi.path_info ), '?' );

		if ( not Len( Trim( uri ) ) ) {
			uri = request[ "javax.servlet.forward.request_uri" ] ?: "";

			if ( not Len( Trim( uri ) ) ) {
				uri = ReReplace( ( cgi.request_url ?: "" ), "^https?://(.*?)/(.*?)(\?.*)?$", "/\2" );
			}
		}

		return uri;
	}

	if ( FileExists( "/config/Routes.cfm" ) ) {
		includeRoutes( "/config/Routes.cfm" );
	}

	addRouteHandler( getModel( "defaultPresideRouteHandler" ) );
	addRouteHandler( getModel( "adminRouteHandler" ) );
	addRouteHandler( getModel( "assetRouteHandler" ) );
</cfscript>