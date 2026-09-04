/**
 * Service providing cron parsing and other cron related utility functions
 *
 * @singleton      true
 * @presideService true
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
