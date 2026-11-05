component {
	property name="applicationsService"        inject="applicationsService";
	property name="adminAuthenticationService" inject="adminAuthenticationService";
	property name="loginService"               inject="loginService";
	property name="sessionStorage"             inject="sessionStorage";
	property name="messageBox"                 inject="messagebox@cbmessagebox";

	public void function preHandler( event, action, eventArguments ) {
		if ( event.isStatelessRequest() && !adminAuthenticationService.allowsStatelessRequest( event.getCurrentEvent() ) ) {
			event.adminAccessDenied();
		}

		if ( !adminAuthenticationService.isAdminAuthenticationExempt( event.getCurrentEvent() ) ) {
			event.denyUnauthenticatedAdminRequest();
		}

		var activeApplication = applicationsService.getActiveApplication( event.getCurrentEvent() );
		var operationSource   = event.getValue( "_psource", "" );

		if ( Len( Trim( operationSource ) ) ) {
			event.setAdminOperationSource( operationSource );
		}

		event.setXFrameOptionsHeader( "SAMEORIGIN" );
		event.setLayout( applicationsService.getLayout( activeApplication ) );
		event.setLanguage( "" );
		event.includeData( {
			  ajaxEndpoint = event.buildAdminLink( linkTo="ajaxProxy" )
			, adminBaseUrl = event.getAdminPath()
			, siteId       = event.getSiteId()
		} );
		event.includeData( event.getCollection() );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:home.title" )
			, link  = event.buildLink( linkTo=applicationsService.getDefaultEvent( activeApplication ) )
		);
	}

}