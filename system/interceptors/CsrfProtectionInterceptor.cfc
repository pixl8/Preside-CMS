component extends="coldbox.system.Interceptor" {
	property name="applicationsService" inject="delayedInjector:applicationsService";
	property name="messageBox"          inject="delayedInjector:messagebox@cbmessagebox";
	property name="i18n"                inject="delayedInjector:i18n";
	property name="featureService"      inject="delayedInjector:featureService";

// PUBLIC
	public void function configure() {}

	public void function preEvent( event ) {
		var valid   = "";
		var persist = "";

		if ( featureService.isFeatureEnabled( "adminCsrfProtection" ) && event.isAdminUser() && _isProtectedAction( event ) && !_isValid( event ) ) {
			persist = event.getCollectionWithoutSystemVars();

			messageBox.error(
				i18n.translateResource( uri="cms:invalidCsrfToken.error" )
			);

			if ( Len( Trim( cgi.http_referer ) ) ) {
				setNextEvent( url=cgi.http_referer, persistStruct=persist );
			}

			setNextEvent( url=event.buildLink( linkTo=applicationsService.getDefaultEvent() ), persistStruct=persist );
		}
	}

// PRIVATE HELPERS
	private boolean function _isProtectedAction( event ) {
		return event.isActionRequest();
	}

	private boolean function _isValid( event ) {
		var csrfToken = event.getValue( name="csrfToken", defaultValue="" );

		return event.validateCsrfToken( token=csrfToken );
	}

}
