component extends="coldbox.system.web.routing.Router" {

	public void function configure() {
		setUniqueUrls( false );
		setExtensionDetection( false );
		setBaseUrl( "/" );

		variables.presideRoutes = [];

		appMapping = getSetting( "appMapping" );
		if ( FileExists( "/#appMapping#/config/Routes.cfm" ) ) {
			include template="/#appMapping#/config/Routes.cfm";
		}

		getSetting( "activeExtensions" ).each( function( ext ){
			if ( FileExists( ext.directory & "/config/Routes.cfm" ) ) {
				include template=ext.directory & "/config/Routes.cfm";
			}
		} );

		var featureService = getModel( "featureService" );

		if ( featureService.isFeatureEnabled( "cms" ) ) {
			addRouteHandler( getModel( dsl="delayedInjector:errorRouteHandler" ) );
		}

		if ( featureService.isFeatureEnabled( "admin" ) ) {
			addRouteHandler( getModel( dsl="delayedInjector:adminRouteHandler" ) );
		}

		if ( featureService.isFeatureEnabled( "assetmanager" ) ) {
			addRouteHandler( getModel( dsl="delayedInjector:assetRouteHandler" ) );
		}

		addRouteHandler( getModel( dsl="delayedInjector:plainStoredFileRouteHandler" ) );

		if ( featureService.isFeatureEnabled( "rulesEngine" ) ) {
			addRouteHandler( getModel( dsl="delayedInjector:rulesEngineConditionsExpressionsJsHandler" ) );
			addRouteHandler( getModel( dsl="delayedInjector:rulesEngineFilterExpressionsJsHandler" ) );
		}

		addRouteHandler( getModel( dsl="delayedInjector:staticAssetRouteHandler" ) );

		if ( featureService.isFeatureEnabled( "emailCenter" ) ) {
			addRouteHandler( getModel( dsl="delayedInjector:emailRouteHandler" ) );
		}

		if ( featureService.isFeatureEnabled( "siteTree" ) ) {
			addRouteHandler( getModel( dsl="delayedInjector:defaultPresideRouteHandler" ) );
		}

		if ( featureService.isFeatureEnabled( "restFramework" ) ) {
			addRouteHandler( getModel( dsl="delayedInjector:restRouteHandler" ) );
		}

		addRouteHandler( getModel( dsl="delayedInjector:standardRouteHandler" ) );

		setSetting( "presideRoutes", presideRoutes );
	}

	function pathInfoProvider( event ) {
		var headers = GetHttpRequestData( false ).headers;
		var uri     = ListFirst( ( headers['X-Original-URL'] ?: (request[ "javax.servlet.forward.request_uri" ] ?: "") ), '?' );
		var qs      = "";

		if ( !Len( Trim( uri ) ) ) {
			uri = cgi.path_info ?: "";

			if ( !Len( Trim( uri ) ) ) {
				uri = ReReplace( ( cgi.request_url ?: "" ), "^https?://(.*?)/(.*?)(\?.*)?$", "/\2" );
			}
		}

		if ( ListLen( headers['X-Original-URL'] ?: "", "?" ) > 1 ) {
			qs = ListRest( headers['X-Original-URL'], "?" );
		}
		if ( !Len( Trim( qs ) ) ) {
			qs = request[ "javax.servlet.forward.query_string" ] ?: ( cgi.query_string ?: "" );
		}

		request[ "preside.path_info" ]    = uri;
		request[ "preside.query_string" ] = qs;

		return uri;
	}

	public void function addRouteHandler( routeHandler ) {
		if ( !IsNull( arguments.routeHandler ) ) {
			ArrayAppend( variables.presideRoutes, arguments.routeHandler );
		}
	}

// overriding getModel() to ensure we always use delayed injector in our Routes.cfm which loads while the interceptors are loading
	public any function getModel( string name, string dsl, struct initArguments={} ) {
		if ( StructKeyExists( arguments, "name" ) ) {
			if ( !getController().getWirebox().containsInstance( arguments.name ) ) {
				return;
			}
			arguments.dsl = "delayedInjector:" & arguments.name;
		} else if ( StructKeyExists( arguments, "dsl" ) && !arguments.dsl.reFindNoCase( "^delayedInjector:" ) && !arguments.dsl.reFindNoCase( "^provider:" ) ) {
			arguments.dsl = "delayedInjector:" & arguments.dsl;
		}

		return super.getModel(
			  dsl           = arguments.dsl ?: NullValue()
			, initArguments = arguments.initArguments
		);
	}
}

