/**
 * @feature emailCenter
 */
component {

	property name="emailStatsService" inject="featureInjector:emailCenter:emailStatsService";

	private void function runAsync() {
		emailStatsService.migrateToSummaryTables();
	}
}