component extends="coldbox.system.Interceptor" {

	property name="adminAuthenticationService" inject="delayedInjector:adminAuthenticationService";
	property name="featureService"             inject="delayedInjector:featureService";

	public void function configure() {}

	public void function preProcess( event ) {
		var eventName = "";

		if ( !featureService.isFeatureEnabled( "admin" ) ) {
			return;
		}

		eventName = event.getCurrentEvent();

		if ( adminAuthenticationService.backstopDeniesStatelessRequest( eventName ) && event.isStatelessRequest() ) {
			event.adminAccessDenied();
		}

		if ( adminAuthenticationService.eventRequiresAdminAuthentication( eventName ) ) {
			event.denyUnauthenticatedAdminRequest();
		}
	}

}
