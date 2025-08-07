/**
 * Handler for the formbuilder submission rules engine context
 *
 * @feature rulesEngine and formBuilder
 */
component {

	property name="formBuilderService" inject="formBuilderService";

	private struct function getPayload() {
		var formId = rc.formBuilderFormSubmitted ?: "";

		if ( isEmptyString( formId ) ) {
			return { formbuilderSubmission=formBuilderService.getFormBuilderSubmissionContextData() };
		}

		return { formbuilderSubmission={ id=formId, formId=formId, submissionId="", data=rc } };
	}

}