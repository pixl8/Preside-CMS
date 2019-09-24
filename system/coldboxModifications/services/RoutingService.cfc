component extends="coldbox.system.web.services.RoutingService" accessors=true {

	public void function onConfigurationLoad() {
		super.onConfigurationLoad( argumentCollection=arguments );

		variables.featureService                   = wirebox.getInstance( dsl="delayedInjector:featureService"                   );
		variables.systemConfigurationService       = wirebox.getInstance( dsl="delayedInjector:systemConfigurationService"       );
		variables.urlRedirectsService              = wirebox.getInstance( dsl="delayedInjector:urlRedirectsService"              );
		variables.siteService                      = wirebox.getInstance( dsl="delayedInjector:siteService"                      );
		variables.tenancyService                   = wirebox.getInstance( dsl="delayedInjector:tenancyService"                   );
		variables.adminRouteHandler                = wirebox.getInstance( dsl="delayedInjector:adminRouteHandler"                );
		variables.assetRouteHandler                = wirebox.getInstance( dsl="delayedInjector:assetRouteHandler"                );
		variables.plainStoredFileRouteHandler      = wirebox.getInstance( dsl="delayedInjector:plainStoredFileRouteHandler"      );
		variables.staticAssetRouteHandler          = wirebox.getInstance( dsl="delayedInjector:staticAssetRouteHandler"          );
		variables.restRouteHandler                 = wirebox.getInstance( dsl="delayedInjector:restRouteHandler"                 );
		variables.multilingualPresideObjectService = wirebox.getInstance( dsl="delayedInjector:multilingualPresideObjectService" );
		variables.multilingualIgnoredUrlPatterns   = wirebox.getInstance( dsl="coldbox:setting:multilingual.ignoredUrlPatterns"  );

		variables.controller.getInterceptorService().registerInterceptor( interceptorClass="preside.system.interceptors.PageCachingInterceptor" );
	}

	public void function onRequestCapture( event, interceptData ) {
		_announceInterception( "prePresideRequestCapture", interceptData );
		_checkRedirectDomains( argumentCollection=arguments );
		if ( featureService.isFeatureEnabled( "sites" ) ) {
			_detectIncomingSite( argumentCollection=arguments );
		}
		_setCustomTenants    ( argumentCollection=arguments );
		_checkUrlRedirects   ( argumentCollection=arguments );
		_detectLanguage      ( argumentCollection=arguments );
		_setPresideUrlPath   ( argumentCollection=arguments );

		if ( !_routePresideSESRequest( argumentCollection=arguments ) ) {
			super.onRequestCapture( argumentCollection=arguments );
		}

		event.setXFrameOptionsHeader();

		_announceInterception( "postPresideRequestCapture", interceptData );
	}

	public void function onBuildLink( event, interceptData ) {
		for( var route in _getPresideRoutes() ){
			if ( route.get().reverseMatch( buildArgs=interceptData, event=event ) ) {
				event.setValue( name="_builtLink", value=route.get().build( buildArgs=interceptData, event=event ), private=true );
				return;
			}
		}
	}

	private function loadRouter(){
		var baseRouter = "coldbox.system.web.routing.Router";

		if( !wirebox.getBinder().mappingExists( baseRouter ) ){
			wirebox.registerNewInstance( name=baseRouter, instancePath=baseRouter );
		}

		wirebox.registerNewInstance( name="router@coldbox", instancePath="preside.system.config.Router" )
		       .setVirtualInheritance( baseRouter )
		       .setThreadSafe( true )
		       .setScope( wirebox.getBinder().SCOPES.SINGLETON );

		variables.router = wirebox.getInstance( "router@coldbox" );
		variables.router.configure();
		variables.router.startup();

		return this;
	}

// private utility methods
	private void function _detectIncomingSite( event, interceptData ) {
		var pathInfo       = _getCGIElement( "path_info", event );
		var domain         = _getCGIElement( "server_name", event );
		var explicitSiteId = event.getValue( name="_sid", defaultValue="" ).trim();
		var site           = {};

		if ( explicitSiteId.len() ) {
			site = siteService.getSite( explicitSiteId );
		}

		if ( adminRouteHandler.match( pathInfo, event ) && event.isAdminUser() ) {
			if ( site.count() ) {
				siteService.setActiveAdminSite( site.id );
			} else {
				site = siteService.getActiveAdminSite( domain=domain );
			}
		} else {
			if ( !site.count() ) {
				site = siteService.matchSite(
					  domain = domain
					, path   = pathInfo
				);
			}

			if ( Len( Trim( site.id ?: "" ) ) && event.isAdminUser() && !_isNonSiteSpecificRequest( pathInfo, event ) ) {
				siteService.setActiveAdminSite( site.id );
			}

			if ( site.isEmpty() ) {
				header statuscode="404" statustext="Not Found";
				abort;
			}
		}

		interceptData.site = site;

		_announceInterception( "onPresideDetectIncomingSite", interceptData );

		event.setSite( interceptData.site );
	}

	private void function _setCustomTenants() {
		tenancyService.setRequestTenantIds();
	}

	private void function _detectLanguage( event, interceptor ) {
		if ( !_skipLanguageDetection( argumentCollection=arguments ) ) {
			var path     = _getCGIElement( "path_info", event );
			var site     = event.getSite();
			var sitePath = site.path.reReplace( "/$", "" );

			if ( sitePath.len() ) {
				path = path.replaceNoCase( sitePath, "" );
			}

			var localeSlug = Trim( ListFirst( path, "/" ) );
			var language   = multilingualPresideObjectService.getDetectedRequestLanguage( localeSlug=localeSlug );

			interceptData.language = language;
			_announceInterception( "onPresideDetectLanguage", interceptData );
			language = interceptData.language ?: QueryNew( "" );

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

	private boolean function _skipLanguageDetection( event, interceptor ) {
		if ( !featureService.isFeatureEnabled( "multilingual" ) ) {
			return true;
		}

		var multilingualUrlsEnabled = systemConfigurationService.getSetting( "multilingual", "urls_enabled", false );
		if ( !IsBoolean( multilingualUrlsEnabled ) || !multilingualUrlsEnabled ) {
			return true;
		}

		var path = _getCGIElement( "path_info", event );
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

	private void function _setPresideUrlPath( event, interceptor ) {
		var site         = event.getSite();
		var pathToRemove = ( site.path ?: "" ).reReplace( "/$", "" );
		var fullPath     = _getCGIElement( "path_info", event );
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

	private boolean function _routePresideSESRequest( event, interceptData ) {
		_announceInterception( "preRoutePresideSESRequest", interceptData );

		var path = event.getCurrentPresideUrlPath();

		for( var route in _getPresideRoutes() ){
			if ( route.match( path=path, event=event ) ) {
				route.translate( path=path, event=event );

				_setEventName( event );

				_announceInterception( "postRoutePresideSESRequest", interceptData );

				return true;
			}
		}

		_announceInterception( "postRoutePresideSESRequest", interceptData );

		return false;
	}

	private void function _setEventName( event ) {
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

	private void function _checkUrlRedirects( event, interceptData ) {
		if ( event.isAjax() ) {
			return;
		}

		interceptData.path    = event.getCurrentUrl( includeQueryString=true );
		interceptData.fullUrl = event.getSiteUrl() & interceptData.path;


		_announceInterception( "onPresideUrlRedirects", interceptData );

		urlRedirectsService.redirectOnMatch(
			  path    = interceptData.path
			, fullUrl = interceptData.fullUrl
		);
	}

	private void function _checkRedirectDomains( event, interceptData ) {
		var domain = LCase( _getCGIElement( "server_name", event ) );
		var redirectUrl = "";

		if ( featureService.isFeatureEnabled( "sites" ) ) {
			var redirectSite = siteService.getRedirectSiteForDomain( domain );

			if ( redirectSite.recordCount && redirectSite.domain != domain ) {
				redirectUrl = redirectSite.protocol & "://" & redirectSite.domain;
				interceptData.redirectFromSite = redirectSite;
			}
		} else {
			var allowedDomains = controller.getSetting( "allowedDomains" );
			var allowed = !allowedDomains.len() || allowedDomains.find( domain );

			if ( !allowed ) {
				redirectUrl = controller.getSetting( "forcessl" ) ? "https" : ( ( cgi.https ?: "" ) == "on" ? "https" : "http" );
				redirectUrl &= "://" & allowedDomains[ 1 ];
			}
		}

		if ( redirectUrl.len() ) {
			var path = _getCGIElement( 'path_info', event );
			var qs   = _getCGIElement( 'query_string', event );
			redirectUrl &= path;
			if ( Len( Trim( qs ) ) ) {
				redirectUrl &= "?" & qs;
			}
			interceptData.redirectFromDomain = domain;
			interceptData.redirectUrl = redirectUrl;

			_announceInterception( "onPresideRedirectDomains", interceptData );

			getController().relocate( url=interceptData.redirectUrl , statusCode=301 );
		}

	}

	private boolean function _isNonSiteSpecificRequest( required string pathInfo, required any event ) {
		return assetRouteHandler.match( pathInfo, event )
		    || plainStoredFileRouteHandler.match( pathInfo, event )
		    || staticAssetRouteHandler.match( pathInfo, event )
		    || restRouteHandler.match( pathInfo, event );
	}

	private array function _getPresideRoutes() {
		if ( !StructKeyExists( variables, "_presideRoutes" ) ) {
			var presideRoutes = controller.getSetting( "presideRoutes" );
			if ( IsArray( presideRoutes ) && presideRoutes.len() ) {
				variables._presideRoutes = presideRoutes;
			} else {
				return [];
			}
		}

		return variables._presideRoutes;
	}

	private any function _getCGIElement( required string cgiElement, required any event ) {
		if ( arguments.cgiElement == "path_info" ){
			if ( StructKeyExists( request, "preside.path_info" ) ) {
				return request[ "preside.path_info" ];
			}

			return variables.router.pathInfoProvider( event=arguments.event );
		}
		return CGI[ arguments.CGIElement ];
	}

	private void function _announceInterception() {
	    return variables.controller.getInterceptorService().processState( argumentCollection=arguments );
	}
}