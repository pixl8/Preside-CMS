/**
 * @feature webflow
 */
component {

	property name="sqlRunner" inject="SqlRunner";

	private void function run() {
		var dsn = getPresideObject( "webflow_configuration" ).getDsn();

		// Step 1: Delete duplicate steps (keep ones pointing to correct config)
		// This handles cases where both old orphaned and new correct steps exist
		// Must run BEFORE updating orphaned steps to avoid unique constraint violations
		sqlRunner.runSql(
			  dsn = dsn
			, sql = "
				DELETE wcs_old FROM webflow_configuration_step wcs_old
				INNER JOIN webflow_configuration_step wcs_new ON wcs_new.step_id = wcs_old.step_id
					AND wcs_new.site = wcs_old.site
					AND wcs_new.id != wcs_old.id
				INNER JOIN webflow_configuration wc_old ON wc_old.id = wcs_old.webflow
				INNER JOIN webflow_configuration wc_new ON wc_new.id = wcs_new.webflow
				WHERE wc_old.webflow_id = wc_new.webflow_id
				  AND wc_old.site != wcs_old.site
				  AND wc_new.site = wcs_new.site
			"
		);

		// Step 2: Update orphaned steps to point to correct configuration
		// These are steps where the step's site doesn't match the configuration's site
		sqlRunner.runSql(
			  dsn = dsn
			, sql = "
				UPDATE webflow_configuration_step wcs
				INNER JOIN webflow_configuration wc_current ON wc_current.id = wcs.webflow
				INNER JOIN webflow_configuration wc_correct ON wc_correct.webflow_id = wc_current.webflow_id
					AND wc_correct.site = wcs.site
					AND wc_correct.is_singleton = 1
					AND wc_correct.instance_ref IS NULL
				SET wcs.webflow = wc_correct.id
				WHERE wc_current.site != wcs.site
				  AND wc_current.is_singleton = 1
				  AND wc_current.instance_ref IS NULL
			"
		);
	}

}
