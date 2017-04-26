/**
 * @expressionContexts formbuilderSubmission
 * @expressionCategory formbuilder
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="formBuilderService"         inject="formBuilderService";

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
		var formItem       = formBuilderService.getFormItem( arguments.fbFormField );
		var fieldName      = formItem.configuration.name ?: "";
		var submittedValue = Val( submissionData[ fieldName ] ?: "" );

		return formId == fbForm && rulesEngineOperatorService.compareNumbers(
			  leftHandSide  = submittedValue
			, operator      = arguments._numericOperator
			, rightHandSide = arguments.value
		);
	}

}
