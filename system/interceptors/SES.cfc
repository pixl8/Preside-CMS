component extends="coldbox.system.interceptors.SES" output=false {

	property name="featureService"                   inject="delayedInjector:featureService";
	property name="systemConfigurationService"       inject="delayedInjector:systemConfigurationService";
	property name="urlRedirectsService"              inject="delayedInjector:urlRedirectsService";
	property name="siteService"                      inject="delayedInjector:siteService";
	property name="adminRouteHandler"                inject="delayedInjector:adminRouteHandler";
	property name="multilingualPresideObjectService" inject="delayedInjector:multilingualPresideObjectService";
	property name="multilingualIgnoredUrlPatterns"   inject="coldbox:setting:multilingual.ignoredUrlPatterns";

	public void function configure() output=false {
		instance.presideRoutes = [];

		super.configure( argumentCollection = arguments );
	}

// the interceptor method
	public void function onRequestCapture( event, interceptData ) output=false {
		_checkRedirectDomains( argumentCollection=arguments );
		_detectIncomingSite  ( argumentCollection=arguments );
		_checkUrlRedirects   ( argumentCollection=arguments );
		_detectLanguage      ( argumentCollection=arguments );
		_setPresideUrlPath   ( argumentCollection=arguments );

		if ( !_routePresideSESRequest( argumentCollection=arguments ) ) {
			super.onRequestCapture( argumentCollection=arguments );
		}
	}


	public void function onBuildLink( event, interceptData ) output=false {
		for( var route in instance.presideRoutes ){
			if ( route.reverseMatch( buildArgs=interceptData, event=event ) ) {
				event.setValue( name="_builtLink", value=route.build( buildArgs=interceptData, event=event ), private=true );
				return;
			}
		}
	}

// public "DSL" methods (to be available to Routes.cfm config file)
	public void function addRouteHandler( required any routeHandler ) output=false {
		ArrayAppend( instance.presideRoutes, arguments.routeHandler );
	}

// overriding the import routes method and making it not catch and rethrow errors (more useful if it just lets the error throw itself with its original message and stack trace, etc.)
	public any function includeRoutes( required string location ) output=false {
		if( ListLast( arguments.location, "." ) != "cfm" ){
			arguments.location &= ".cfm";
		}

		// Try to remove pathInfoProvider, just in case
		StructDelete( variables, "pathInfoProvider" );
		StructDelete( this     , "pathInfoProvider" );

		$include( arguments.location );

		return this;
	}

// overriding getModel() to ensure we always use delayed injector in our Routes.cfm which loads while the interceptors are loading
	public any function getModel( string name, string dsl, struct initArguments={} ) {
		if ( arguments.keyExists( "name" ) ) {
			arguments.dsl = "delayedInjector:" & arguments.name;
		} else if ( arguments.keyExists( "dsl" ) && !arguments.dsl.startsWith( "delayedInjector:" ) && !arguments.dsl.startsWith( "provider:" ) ) {
			arguments.dsl = "delayedInjector:" & arguments.dsl;
		}

		return super.getModel(
			  dsl           = arguments.dsl ?: NullValue()
			, initArguments = arguments.initArguments
		);
	}

// private utility methods
	private void function _detectIncomingSite( event, interceptData ) output=false {
		var pathInfo = super.getCGIElement( "path_info", event );
		var domain   = super.getCGIElement( "server_name", event );
		var site     = "";

		if ( adminRouteHandler.match( pathInfo, event ) && event.isAdminUser() ) {
			site = siteService.getActiveAdminSite( domain=domain );
		} else {
			site = siteService.matchSite(
				  domain = domain
				, path   = pathInfo
			);
			if ( Len( Trim( site.id ?: "" ) ) ) {
				siteService.setActiveAdminSite( site.id );
			}

			if ( site.isEmpty() ) {
				throw(
					  type      = "presidecms.site.not.found"
					, message   = "There is no PresideCMS site configured with the current domain, [#super.getCGIElement( 'server_name', event )#]"
					, detail    = "If you are the system administrator, and expect the domain to work, please update the site's main domain either in the database or through the administrator if accessible."
					, errorCode = 404
				);
			}
		}

		event.setSite( site );
	}

	private void function _detectLanguage( event, interceptor ) output=false {
		if ( !_skipLanguageDetection( argumentCollection=arguments ) ) {
			var path     = super.getCGIElement( "path_info", event );
			var site     = event.getSite();
			var sitePath = site.path.reReplace( "/$", "" );

			if ( sitePath.len() ) {
				path = path.replaceNoCase( sitePath, "" );
			}

			var localeSlug = Trim( ListFirst( path, "/" ) );
			var language   = multilingualPresideObjectService.getDetectedRequestLanguage( localeSlug=localeSlug );

			if ( language.recordCount ) {
				event.setLanguage( language.id );
				event.setLanguageSlug( language.slug );
				event.setLanguageCode( language.iso_code );

				if ( language.slug != localeSlug ) {
					var qs          = Len( Trim( request[ "preside.query_string" ] ?: "" ) ) ? "?#request[ "preside.query_string" ]#" : "";
					var redirectUrl = sitePath & "/" & language.slug & path & qs;

					location url=redirectUrl addtoken=false;
				}
			}
		}
	}

	private boolean function _skipLanguageDetection( event, interceptor ) output=false {
		if ( !featureService.isFeatureEnabled( "multilingual" ) ) {
			return true;
		}

		var multilingualUrlsEnabled = systemConfigurationService.getSetting( "multilingual", "urls_enabled", false );
		if ( !IsBoolean( multilingualUrlsEnabled ) || !multilingualUrlsEnabled ) {
			return true;
		}

		var path = super.getCGIElement( "path_info", event );
		if ( adminRouteHandler.match( path, event ) ) {
			return true;
		}

		for( var pattern in multilingualIgnoredUrlPatterns) {
			if ( path.reFindNoCase( pattern ) ) {
				return true;
			}
		}

		return false;
	}

	private void function _setPresideUrlPath( event, interceptor ) output=false {
		var site         = event.getSite();
		var pathToRemove = ( site.path ?: "" ).reReplace( "/$", "" );
		var fullPath     = super.getCGIElement( "path_info", event );
		var presidePath  = "";
		var languageSlug = event.getLanguageSlug();
		if ( Len( Trim( languageSlug ) ) ) {
			pathToRemove = pathToRemove & "/" & languageSlug & "/";
		}
		if ( pathToRemove.len() ) {
			presidePath = fullPath.replaceNoCase( pathToRemove, "" );
			presidePath = presidePath.reReplace( "^([^/]|$)", "/\1" );
		} else {
			presidePath = fullPath;
		}


		event.setCurrentPresideUrlPath( presidePath );
	}

	private boolean function _routePresideSESRequest( event, interceptData ) output=false {
		var path = event.getCurrentPresideUrlPath();

		for( var route in instance.presideRoutes ){
			if ( route.match( path=path, event=event ) ) {
				route.translate( path=path, event=event );

				_setEventName( event );

				return true;
			}
		}

		return false;
	}

	private void function _setEventName( event ) output=false {
		var rc = event.getCollection();

		if ( Len( Trim( rc.handler ?: "" ) ) ) {
			var action = rc.action ?: super.getDefaultFrameworkAction();
			var evName = rc.handler & "." & action;

			if ( Len( Trim( rc.module ?: "" ) ) ) {
				evName = rc.module & ":" & evName;
			}

			rc[ instance.eventName ] = evName;
		}
	}

	private void function _checkUrlRedirects( event, interceptData ) output=false {
		if ( event.isAjax() ) {
			return;
		}

		var path    = event.getCurrentUrl( includeQueryString=true );
		var fullUrl = event.getBaseUrl() & path;

		urlRedirectsService.redirectOnMatch(
			  path    = path
			, fullUrl = fullUrl
		);
	}

	private void function _checkRedirectDomains( event, interceptData ) output=false {
		var domain       = super.getCGIElement( "server_name", event );
		var redirectSite = siteService.getRedirectSiteForDomain( domain );

		if ( redirectSite.recordCount && redirectSite.domain != domain ) {
			var path        = super.getCGIElement( 'path_info', event );
			var qs          = super.getCGIElement( 'query_string', event );
			var redirectUrl = redirectSite.protocol & "://" & redirectSite.domain & path;

			if ( Len( Trim( qs ) ) ) {
				redirectUrl &= "?" & qs;
			}
			getController().setNextEvent( url=redirectUrl, statusCode=301 );
		}
	}
}