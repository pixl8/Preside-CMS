component {
	property name="websiteLoginService" inject="websiteLoginService";

<!--- VIEWLETS --->
	private string function notFound( event, rc, prc, args={} ) {
		event.setHTTPHeader( statusCode="404" );
		event.setHTTPHeader( name="X-Robots-Tag", value="noindex" );

		if ( event.isAdminRequest() ){
			if ( !event.isAdminUser() ) {
				setNextEvent( url=event.buildAdminLink( "login" ) );
			}

			return renderView( view="/admin/errorPages/notFound" );
		}

		if ( isFeatureEnabled( "redirectErrorPages" ) ) {
			setNextEvent( url=event.buildLink( page="notFound" ) );
		}

		event.initializePresideSiteteePage( systemPage="notFound" );
		return renderView( view="/errors/notFound", presideobject="notFound", id=event.getCurrentPageId(), args=args );
	}

	private string function accessDeniedPageType( event, rc, prc, args={} ) {
		args.reason = "INSUFFICIENT_PRIVILEGES";
		return renderViewlet( event="errors.accessDenied", args=args );
	}

	private string function accessDenied( event, rc, prc, args={} ) {
		event.setHTTPHeader( statusCode="401" );
		event.setHTTPHeader( name="X-Robots-Tag"    , value="noindex" );
		event.setHTTPHeader( name="WWW-Authenticate", value='Website realm="website"' );

		switch( args.reason ?: "" ){
			case "INSUFFICIENT_PRIVILEGES":
				if ( isFeatureEnabled( "redirectErrorPages" ) ) {
					setNextEvent( url=event.buildLink( page="accessDenied" ) );
				}
				event.initializePresideSiteteePage( systemPage="accessDenied" );
				return renderView( view="/errors/insufficientPrivileges", presideobject="accessDenied", id=event.getCurrentPageId(), args=args );
			default:
				websiteLoginService.setPostLoginUrl( Len( Trim( args.postLoginUrl ?: "" ) ) ? args.postLoginUrl : event.getCurrentUrl() );
				if ( isFeatureEnabled( "redirectErrorPages" ) ) {
					setNextEvent( url=event.buildLink( page="login" ), persistStruct={ message="LOGIN_REQUIRED" } );
				}

				event.initializePresideSiteteePage( systemPage="login" );
				return renderView( view="/errors/loginRequired", args=args );
		}
	}

	private string function maintenanceMode( event, rc, prc, args={} ) {
		args.message = renderContent( renderer="richeditor", data=args.message ?: "", context=[ "maintenanceMode", "website" ] );
		args.title   = Len( Trim( args.title ?: "" ) ) ? args.title : "We're sorry, this site is currently down for maintenance";

		return renderView( view="/errors/maintenanceMode", args=args );
	}
}

