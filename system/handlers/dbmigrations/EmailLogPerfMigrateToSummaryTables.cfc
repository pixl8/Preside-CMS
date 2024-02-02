component {

	property name="emailStatsService" inject="emailStatsService";

	private void function runAsync() {
		emailStatsService.migrateToSummaryTables();
	}
}