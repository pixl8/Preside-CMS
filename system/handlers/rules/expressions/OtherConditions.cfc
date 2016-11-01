/**
 * Expression handler for "All/Any of the following conditions are/are not true:"
 *
 */
component {

	property name="rulesEngineConditionService" inject="rulesEngineConditionService";

	/**
	 * @conditions.fieldType condition
	 */
	private boolean function evaluateExpression(
		  required string  conditions
		,          boolean _all = true
		,          boolean _are = true
	) {
		var result = _all;

		for( var condition in conditions.listToArray() ) {
			var evaluation = rulesEngineConditionService.evaluateCondition(
				  conditionId = condition
				, context     = context ?: "global"
				, payload     = payload ?: {}
			);

			if ( _all ) {
				if ( _are != evaluation ) {
					return false;
				}
			} else {
				if ( _are == evaluation ) {
					return true;
				}
			}
		}

		return result;
	}

}