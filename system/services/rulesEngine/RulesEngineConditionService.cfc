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
	/**
	 * @expressionService.inject rulesEngineExpressionService
	 *
	 */
	public any function init( required any expressionService ) {
		_setExpressionService( arguments.expressionService );
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
		, required any    validationResult
	) {
		if ( !IsJson( arguments.condition ) ) {
			return _malformedError( arguments.validationResult );
		}

		var parsedCondition = DeserializeJson( arguments.condition );

		if ( !IsArray( parsedCondition ) ) {
			return _malformedError( arguments.validationResult );
		}

		return _validateConditionGroup( parsedCondition, arguments.context, arguments.validationResult );
	}

	/**
	 * Evaluates a given JSON condition by logically
	 * evaluating each of its expressions with the given
	 * payload and context.
	 *
	 * @autodoc
	 * @condition.hint JSON condition containing expressions to evaluate
	 * @context.hint   The context of the evaluation, e.g. 'webrequest', or 'workflow', etc.
	 * @payload.hint   Payload for the given context, e.g. a structure containing workflow state, or information about the current web request
	 */
	public boolean function evaluateCondition(
		  required string condition
		, required string context
		, required struct payload
	) {
		return true;
	}

// PRIVATE HELPERS
	private boolean function _validateConditionGroup(
		  required array  group
		, required string context
		, required any    validationResult
	) {
		var isValid = true;
		var validJoins = "^(and|or)$";

		for( var i=1; i<=arguments.group.len(); i++ ){
			var item     = arguments.group[ i ];
			var isOddRow = ( i mod 2 ) == 1;

			if ( isOddRow ) {
				if ( IsArray( item ) ) {
					isValid = _validateConditionGroup( item, arguments.context, arguments.validationResult );
					if ( !isValid ) {
						return false;
					}
				} else if ( IsStruct( item ) ) {
					if ( !item.keyExists( "expression" ) || !item.keyExists( "fields" ) ) {
						return _malformedError( arguments.validationResult );
					}
					isValid = _getExpressionService().isExpressionValid(
						  expressionId     = item.expression
						, fields           = item.fields
						, context          = arguments.context
						, validationResult = arguments.validationResult
					);
					if ( !isValid ) {
						return false;
					}
				} else {
					return _malformedError( arguments.validationResult );
				}
			} else if ( IsSimpleValue( item ) ) {
				if ( !item.reFindNoCase( validJoins ) ) {
					return _malformedError( arguments.validationResult );
				}
			} else {
				return _malformedError( arguments.validationResult );
			}
		}
		return true;
	}

	private boolean function _malformedError( required any validationResult ) {
		arguments.validationResult.setGeneralMessage( "The passed condition was malformed and could not be read" );
		return false;
	}

// GETTERS AND SETTERS
	private any function _getExpressionService() {
		return _expressionService;
	}
	private void function _setExpressionService( required any expressionService ) {
		_expressionService = arguments.expressionService;
	}

}