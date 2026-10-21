/**
 * Service providing cron parsing and other cron related utility functions
 * This service is deprecated and may be removed in a future version, it
 * exists only to provide backwards compatibility with existing code.
 * Use the chrono module instead.
 *
 * @deprecated     true
 * @singleton      true
 * @presideService true
 * @feature        taskmanager
 */
component displayName="Cron util" {

	property name="chrono" inject="chrono@chrono";

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public string function validateExpression( required string crontabExpression ) {
		return chrono.validateExpression( argumentCollection=arguments );
	}

	public string function getNextRunDate( required string crontabExpression, date lastRun=Now() ) {
		return chrono.getNextRunDate( argumentCollection=arguments );
	}

	public string function describeCronTabExression( required string crontabExpression, required string locale ) {
		return chrono.describeCronTabExression( argumentCollection=arguments );
	}

}
