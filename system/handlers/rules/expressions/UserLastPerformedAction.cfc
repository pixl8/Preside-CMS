/**
 * Expression handler for "User's has performed some action within the last x days"
 *
 * @feature websiteUsers
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="websiteUserActionService"   inject="websiteUserActionService";

	/**
	 * @expression         true
	 * @expressionContexts webrequest,user
	 * @action.fieldType   websiteUserAction
	 * @action.multiple    false
	 * @days.fieldLabel    rules.expressions.UserLastPerformedAction.webrequest:field.days.config.label
	 */
	private boolean function webRequest(
		  required string  action
		, required numeric days
		,          boolean _did = true
		,          string  _numericOperator = "gt"
	) {
		if ( ListLen( action, "." ) != 2 ) {
			return false;
		}

		var lastPerformedDate = websiteUserActionService.getLastPerformedDate(
			  type   = ListFirst( action, "." )
			, action = ListLast( action, "." )
			, userId = payload.user.id ?: ""
		);

		if ( !IsDate( lastPerformedDate ) ) {
			return !_did;
		}

		var daysDifference = DateDiff( "d", lastPerformedDate, Now() );
		var result         = rulesEngineOperatorService.compareNumbers( daysDifference, arguments._numericOperator, arguments.days );

		return _did ? result : !result;
	}

}