component extends="coldbox.system.Interceptor" output=false {
	property name="applicationsService"   inject="delayedInjector:applicationsService";

// PUBLIC
	public void function configure() output=false {}

	public void function preEvent( event ) output=false {
		var valid   = "";
		var persist = "";

		if ( event.isAdminUser() && _isProtectedAction( event ) && !_isValid( event ) ) {
			persist = event.getCollectionWithoutSystemVars();

			getPlugin( "MessageBox" ).error(
				getPlugin( "i18n" ).translateResource( uri="cms:invalidCsrfToken.error" )
			);

			if ( Len( Trim( cgi.http_referer ) ) ) {
				setNextEvent( url=cgi.http_referer, persistStruct=persist );
			}

			// TODO, something better here!
			setNextEvent( url=event.buildLink( linkTo=applicationsService.getDefaultEvent() ), persistStruct=persist );
		}
	}

// PRIVATE HELPERS
	private boolean function _isProtectedAction( event ) output=false {
		return event.isActionRequest();
	}

	private boolean function _isValid( event ) output=false {
		var csrfToken = event.getValue( name="csrfToken", defaultValue="" );

		return event.validateCsrfToken( token=csrfToken );
	}

}