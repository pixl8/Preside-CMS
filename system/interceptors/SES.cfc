component extends="coldbox.system.interceptors.SES" output=false {

	property name="siteService" inject="siteService";
	property name="adminRouteHandler" inject="adminRouteHandler";
	property name="presideObjectService" inject="presideObjectService";

	public void function configure() output=false {
		instance.presideRoutes = [];

		super.configure( argumentCollection = arguments );
	}

// the interceptor method
	public void function onRequestCapture( event, interceptData ) output=false {
		_checkRedirectDomains( argumentCollection=arguments );
		_detectIncomingSite( argumentCollection=arguments );

		if ( !_routePresideSESRequest( argumentCollection = arguments ) ) {
			super.onRequestCapture( argumentCollection=arguments );
		}
	}

	public void function onBuildLink( event, interceptData ) output=false {
		for( var route in instance.presideRoutes ){
			if ( route.reverseMatch( buildArgs=interceptData ) ) {
				event.setValue( name="_builtLink", value=route.build( buildArgs=interceptData ), private=true );
				return;
			}
		}
	}

// public "DSL" methods (to be available to Routes.cfm config file)
	public void function addRouteHandler( required any routeHandler ) output=false {
		ArrayAppend( instance.presideRoutes, arguments.routeHandler );
	}

// private utility methods
	private void function _detectIncomingSite( event, interceptData ) output=false {
		var pathInfo = super.getCGIElement( "path_info", event );
		var site     = "";

		siteService.ensureDefaultSiteExists();

		if ( adminRouteHandler.match( pathInfo, event ) && event.isAdminUser() ) {
			site = siteService.getActiveAdminSite();
		} else {
			site = siteService.matchSite(
				  domain = super.getCGIElement( "server_name", event )
				, path   = pathInfo
			);
		}

		event.setSite( site );
	}

	private boolean function _routePresideSESRequest( event, interceptData ) output=false {
		var path = super.getCGIElement( "path_info", event );

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