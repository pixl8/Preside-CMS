/**
 * @expressionContexts formbuilderSubmission
 * @expressionCategory formbuilder
 */
component {

	property name="formBuilderService" inject="formBuilderService";

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
		var formItem       = formBuilderService.getFormItem( arguments.fbFormField );
		var fieldName      = formItem.configuration.name ?: "";
		var submittedValue = submissionData[ fieldName ] ?: "";
		var isChecked      = ( submittedValue.len() && submittedValue != 0 );

		return formId == fbForm && arguments._is == isChecked;
	}

}
