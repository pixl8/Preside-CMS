component extends="coldbox.system.Interceptor" {

	property name="websiteUserImpersonationService" inject="delayedInjector:websiteUserImpersonationService";

// PUBLIC
	public void function configure() {}

	public void function prePresideRequestCapture( event, interceptData ) {
		var rc = arguments.event.getCollection();
		if ( !StructKeyExists( rc, "impersonate" ) ) {
			return;
		}

		var targetUrl = websiteUserImpersonationService.resolve( rc.impersonate );
		if ( len( targetUrl ) ) {
			setNextEvent( url=targetUrl );
		}
	}
}