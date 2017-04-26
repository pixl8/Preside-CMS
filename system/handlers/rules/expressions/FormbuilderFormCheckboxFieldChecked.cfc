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
		,          boolean _is = true
	) {
		var submissionData = payload.formbuilderSubmission.data ?: {};
		var formId         = payload.formbuilderSubmission.id   ?: "";
		var submittedValue = submissionData[ arguments.fbformfield ] ?: "";

		var isChecked = ( submittedValue.len() && submittedValue != 0 );

		return formId == fbForm && arguments._is == isChecked;
	}

}
