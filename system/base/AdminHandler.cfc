/**
 * @feature admin
 */
component {
	property name="applicationsService"        inject="applicationsService";
	property name="adminAuthenticationService" inject="adminAuthenticationService";

	public void function preHandler( event, action, eventArguments ) {
		if ( event.isStatelessRequest() ) {
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
			, link  = applicationsService.getDefaultUrl( applicationId=activeApplication, siteId=event.getSiteId() )
		);
	}

}