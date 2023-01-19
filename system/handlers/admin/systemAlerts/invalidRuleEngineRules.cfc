component {
	property name="validationEngine"    inject="ValidationEngine";
	property name="conditionService"    inject="RulesEngineConditionService";
	property name="systemAlertsService" inject="SystemAlertsService";

	private void function runCheck( required systemAlertCheck check ) {
		var invalidRules  = [];
		var ruleFilter    = "";
		var ruleParams    = {};
		var existingAlert = systemAlertsService.getAlert( type="invalidRuleEngineRules" );

		if ( arrayLen( existingAlert.data.invalidRules ?: [] ) ) {
			ruleFilter = "id in (:id) OR datecreated >= :datecreated";

			ruleParams.id          = existingAlert.data.invalidRules;
			ruleParams.datecreated = existingAlert.datecreated;
		}

		var allRules = getPresideObject( "rules_engine_condition" ).selectData(
			  filter       = ruleFilter
			, filterParams = ruleParams
			, selectFields = [ "id", "context", "filter_object", "expressions" ]
		);

		for ( var rule in allRules ) {
			var isRuleValid = conditionService.validateCondition(
				  condition        = rule.expressions   ?: ""
				, context          = rule.context       ?: ""
				, validationResult = validationEngine.newValidationResult()
				, filterObject     = rule.filter_object ?: ""
			);

			if ( !isRuleValid ) {
				arrayAppend( invalidRules, rule.id );
			}
		}

		if ( arrayLen( invalidRules ) ) {
			check.fail();
			check.setData( { invalidRules=invalidRules } );
		} else {
			check.pass();
		}
	}

	private string function render( event, rc, prc, args={} ) {
		return renderView( view="/admin/systemAlerts/invalidRuleEngineRules/render", args=args );
	}


// CONFIG SETTINGS
	private boolean function runAtStartup() {
		return true;
	}

	private string function defaultLevel() {
		return "critical";
	}
}