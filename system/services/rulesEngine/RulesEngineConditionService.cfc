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
	 * Returns a structure with details of the condition
	 * that matches the supplied condition ID. Struct keys:
	 * `id`, `name`, `context` and `expression`. Returns an empty
	 * struct when the condition is not found.
	 *
	 * @autodoc
	 * @conditionId.hint ID of the condition to get.
	 */
	public struct function getCondition( required string conditionId ) {
		var conditionRecord = $getPresideObject( "rules_engine_condition" ).selectData( id=arguments.conditionId );

		if ( conditionRecord.recordCount ) {
			return {
				  id          = arguments.conditionId
				, name        = conditionRecord.condition_name
				, context     = conditionRecord.context
				, expressions = DeSerializeJson( conditionRecord.expressions )
			};
		}

		return {};
	}

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
	 * Evaluates a given condition by logically
	 * evaluating each of its expressions with the given
	 * payload and context.
	 *
	 * @autodoc
	 * @conditionId.hint ID of the condition stored in the database
	 * @context.hint     The context of the evaluation, e.g. 'webrequest', or 'workflow', etc.
	 * @payload.hint     Payload for the given context, e.g. a structure containing workflow state, or information about the current web request
	 */
	public boolean function evaluateCondition(
		  required string conditionId
		, required string context
		, required struct payload
	) {
		var condition = getCondition( arguments.conditionId );

		if ( condition.isEmpty() ) {
			return false;
		}

		return _evaluateExpressionArray(
			  expressionArray = condition.expressions
			, context         = arguments.context
			, payload         = arguments.payload
		);
	}

	/**
	 * Returns a query record of the condition
	 * matched by the given id
	 *
	 * @autodoc
	 * @conditionId.hint ID of the condition to get.
	 */
	public query function getConditionRecord( required string conditionId ) {
		return $getPresideObject( "rules_engine_condition" ).selectData( id=arguments.conditionId );
	}

	/**
	 * Validator for the preside validation service
	 *
	 * @validator
	 * @validatorMessage cms:validation.rulesEngineCondition.default
	 */
	public boolean function rulesEngineCondition( required string value, required struct data ) {
		return validateCondition(
			  condition        = arguments.value
			, context          = ( arguments.data.context ?: ( rc.context ?: "global" ) )
			, validationResult = new preside.system.services.validation.ValidationResult()
		);
	}
	public string function rulesEngineCondition_js() {
		return "function(){ return true; }";
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

	private boolean function _evaluateExpressionArray(
		  required array  expressionArray
		, required string context
		, required struct payload
	) {
		var currentEvaluation = true;
		var currentJoin       = "and";
		var expressionResult  = true;

		for( var i=1; i<=arguments.expressionArray.len(); i++ ) {
			var item     = arguments.expressionArray[i];
			var isOddRow = ( i mod 2 == 1 );

			if ( isOddRow ) {
				if ( IsArray( item ) ) {
					expressionResult = _evaluateExpressionArray(
						  expressionArray = item
						, context         = arguments.context
						, payload         = arguments.payload
					);
				} else {
					expressionResult = _getExpressionService().evaluateExpression(
						  expressionId     = item.expression
						, context          = arguments.context
						, payload          = arguments.payload
						, configuredFields = item.fields
					);
				}

				if ( currentJoin == "and" ) {
					currentEvaluation = currentEvaluation && expressionResult;
				} else {
					currentEvaluation = currentEvaluation || expressionResult;
				}
			} else {
				currentJoin = item;
				if ( currentJoin == "and" && !currentEvaluation ) {
					return false;
				} else if ( currentJoin == "or" && currentEvaluation ) {
					return true;
				}
			}
		}

		return currentEvaluation;
	}

// GETTERS AND SETTERS
	private any function _getExpressionService() {
		return _expressionService;
	}
	private void function _setExpressionService( required any expressionService ) {
		_expressionService = arguments.expressionService;
	}

}