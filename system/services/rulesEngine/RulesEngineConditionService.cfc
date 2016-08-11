/**
 * Provides logic for dealing with rules engine conditions.
 * i.e., validating and evaluating conditions as well
 * as storing them in the database.
 * \n
 * See [[rules-engine]] for more details.
 *
 * @singleton
 * @presideservice
 * @autodoc
 *
 */
component displayName="RulesEngine Condition Service" {

// CONSTRUCTOR
	public any function init() {
		return this;
	}


// PUBLIC API

	/**
	 * Validates the passed JSON condition string
	 * for the given context. Returns true when valid,
	 * false otherwise. Sets any errors in the passed
	 * [[api-validationresult]] object.
	 *
	 * @autodoc
	 * @condition.hint        JSON condition string
	 * @context.hint          Context in which the condition is designed to be used
	 * @validationResult.hint A [[api-validationresult]] object, used to collect detailed validation errors
	 */
	public boolean function validateCondition(
		  required string condition
		, required string context
		, required any validationResult
	) {
		if ( !IsJson( arguments.condition ) ) {
			arguments.validationResult.setGeneralMessage( "The passed condition was malformed and could not be read" );
			return false;
		}

		return true;
	}

}