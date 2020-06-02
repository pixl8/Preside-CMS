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
		  required string fbform
		, required string fbformfield
		,          struct _time = {}
	) {
		var submissionData = payload.formbuilderSubmission.data ?: {};
		var formId         = payload.formbuilderSubmission.id   ?: "";
		var formItem       = formBuilderService.getFormItem( arguments.fbFormField );
		var fieldName      = formItem.configuration.name ?: "";
		var submittedValue = submissionData[ fieldName ] ?: "";


		if ( !IsDate( submittedValue ) ) {
			return false;
		}

		if ( formId != fbForm ) {
			return false;
		}

		if ( IsDate( _time.to ?: "" ) && _time.to < submittedValue ) {
			return false;
		}

		if ( IsDate( _time.from ?: "" ) && _time.from > submittedValue ) {
			return false;
		}

		return true;
	}

}
