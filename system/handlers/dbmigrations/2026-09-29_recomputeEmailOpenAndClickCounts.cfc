/**
 * @feature emailCenter
 */
component {

	property name="emailLoggingService" inject="delayedInjector:emailLoggingService";

	private boolean function isEnabled() {
		return isFeatureEnabled( "emailCenter" );
	}

	private void function runAsync() {
		emailLoggingService.recomputeOpenAndClickCounts();
	}

}
