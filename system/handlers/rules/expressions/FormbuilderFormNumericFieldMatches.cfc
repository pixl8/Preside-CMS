/**
 * @expressionContexts formbuilderSubmission
 * @expressionCategory formbuilder
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

	/**
	 * @fbform.fieldtype      object
	 * @fbform.object         formbuilder_form
	 * @fbform.multiple       false
	 * @fbformfield.fieldtype formbuilderField
	 *
	 */
	private boolean function evaluateExpression(
		  required string  fbform
		, required string  fbformfield
		, required numeric value
		,          string  _numericOperator = "eq"
	) {
		var submissionData = payload.formbuilderSubmission.data ?: {};
		var formId         = payload.formbuilderSubmission.id   ?: "";
		var submittedValue = Val( submissionData[ arguments.fbformfield ] ?: "" );

		return formId == fbForm && rulesEngineOperatorService.compareNumbers(
			  leftHandSide  = submittedValue
			, operator      = arguments._numericOperator
			, rightHandSide = arguments.value
		);
	}

}
