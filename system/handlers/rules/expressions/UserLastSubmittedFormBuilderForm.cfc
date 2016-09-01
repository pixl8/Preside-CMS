/**
 * Expression handler for "User's has submitted a specific form within the last x days"
 *
 * @feature websiteUsers
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="websiteUserActionService"   inject="websiteUserActionService";

	/**
	 * @expression         true
	 * @expressionContexts webrequest,user
	 * @fbform.fieldType   object
	 * @fbform.object      formbuilder_form
	 * @fbform.multiple    false
	 * @days.fieldLabel    rules.expressions.UserLastSubmittedFormBuilderForm.webrequest:field.days.config.label
	 */
	private boolean function webRequest(
		  required string  fbform
		, required numeric days
		,          string  _numericOperator = "gt"
	) {
		if ( ListLen( action, "." ) != 2 ) {
			return false;
		}

		var lastPerformedDate = websiteUserActionService.getLastPerformedDate(
			  type        = "formbuilder"
			, action      = "submitform"
			, userId      = payload.user.id ?: ""
			, identifiers = [ arguments.fbform ]
		);

		if ( !IsDate( lastPerformedDate ) ) {
			return false;
		}

		var daysDifference = DateDiff( "d", lastPerformedDate, Now() );

		return rulesEngineOperatorService.compareNumbers( daysDifference, arguments._numericOperator, arguments.days );
	}

}