component {
	property name="validationEngine"    inject="ValidationEngine";
	property name="conditionService"    inject="RulesEngineConditionService";

	private void function runCheck( required systemAlertCheck check ) {
		var conditionId = arguments.check.getReference();
		if ( !Len( conditionId ) ) {
			return;
		}

		var condition = getPresideObject( "rules_engine_condition" ).selectData(
			  id           = conditionId
			, selectFields = [ "id", "context", "filter_object", "expressions" ]
		);
		if ( !condition.recordcount ) {
			return;
		}

		var isValid = conditionService.validateCondition(
			  condition        = condition.expressions   ?: ""
			, context          = condition.context       ?: ""
			, validationResult = validationEngine.newValidationResult()
			, filterObject     = condition.filter_object ?: ""
		);

		if ( !isValid ) {
			arguments.check.fail();
		}
	}

	private string function render( event, rc, prc, args={} ) {
		return renderView( view="/admin/systemAlerts/invalidRuleEngineRules/render", args=args );
	}


// CONFIG SETTINGS
	private boolean function runAtStartup() {
		return true;
	}

	private array function references() {
		var conditions = getPresideObject( "rules_engine_condition" ).selectData( selectFields=[ "id" ] );
		return valueArray( conditions, "id" );
	}

	private string function defaultLevel() {
		return "critical";
	}
}