component extends="coldbox.system.interceptors.SES" output=false {

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

// private utility methods
	private void function _detectIncomingSite( event, interceptData ) output=false {
		var pathInfo = super.getCGIElement( "path_info", event );
		var site     = "";

		if ( _getAdminRouteHandler().match( pathInfo, event ) && event.isAdminUser() ) {
			site = _getSiteService().getActiveAdminSite();
		} else {
			site = _getSiteService().matchSite(
				  domain = super.getCGIElement( "server_name", event )
				, path   = pathInfo
			);
			if ( Len( Trim( site.id ?: "" ) ) ) {
				_getSiteService().setActiveAdminSite( site.id );
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
		var redirectSite = _getSiteService().getRedirectSiteForDomain( domain );

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

	private any function _getSiteService() output=false {
		if ( not StructKeyExists( variables, "_siteService" ) ) {
			_siteService = getModel( "siteService" );
		}

		return _siteService;
	}

	private any function _getAdminRouteHandler() output=false {
		if ( not StructKeyExists( variables, "_adminRouteHandler" ) ) {
			_adminRouteHandler = getModel( "adminRouteHandler" );
		}

		return _adminRouteHandler;
	}
}