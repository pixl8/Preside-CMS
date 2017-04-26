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
		,          struct _time = {}
	) {
		var submissionData = payload.formbuilderSubmission.data ?: {};
		var formId         = payload.formbuilderSubmission.id   ?: "";
		var submittedValue = submissionData[ arguments.fbformfield ] ?: "";

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
