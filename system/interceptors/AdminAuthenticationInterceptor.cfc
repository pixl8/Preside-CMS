component extends="coldbox.system.Interceptor" {

	property name="adminAuthenticationService" inject="delayedInjector:adminAuthenticationService";

	public void function configure() {}

	public void function preProcess( event ) {
		var eventName = "";

		eventName = event.getCurrentEvent();

		if ( adminAuthenticationService.backstopDeniesStatelessRequest( eventName ) && event.isStatelessRequest() ) {
			event.adminAccessDenied();
		}

		if ( adminAuthenticationService.eventRequiresAdminAuthentication( eventName ) ) {
			event.denyUnauthenticatedAdminRequest();
		}
	}

}
