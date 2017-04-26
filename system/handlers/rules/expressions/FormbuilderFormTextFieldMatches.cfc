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
		  required string fbform
		, required string fbformfield
		, required string value
		,          string  _stringOperator = "eq"
	) {
		var submissionData = payload.formbuilderSubmission.data ?: {};
		var formId         = payload.formbuilderSubmission.id   ?: "";
		var submittedValue = submissionData[ arguments.fbformfield ] ?: "";

		return formId == fbForm && rulesEngineOperatorService.compareStrings(
			  leftHandSide  = submittedValue
			, operator      = arguments._stringOperator
			, rightHandSide = arguments.value
		);
	}

}
