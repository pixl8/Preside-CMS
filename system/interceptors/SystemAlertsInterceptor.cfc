component extends="coldbox.system.Interceptor" {
	property name="systemAlertsService" inject="delayedInjector:SystemAlertsService";

	public void function configure() {}

	public void function onApplicationStart() {
		systemAlertsService.runStartupChecks();
	}

	public void function onClearSettingsCache( event, interceptData ) {
		var category = interceptData.category ?: "";
		if ( category == "dynamicform" ) {
			return;
		}

		systemAlertsService.runWatchedSettingsChecks( category );
	}
}