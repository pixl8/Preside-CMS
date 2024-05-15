component {

	property name="emailStatsService" inject="featureInjector:emailCenter:emailStatsService";

	private boolean function isEnabled() {
		return isFeatureEnabled( "emailCenter" );
	}

	private void function runAsync() {
		emailStatsService.migrateToSummaryTables();
	}
}