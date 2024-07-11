/**
 * Handler for the formbuilder submission rules engine context
 *
 * @feature rulesEngine and formBuilder
 */
component {

	property name="formBuilderService" inject="formBuilderService";

	private struct function getPayload() {
		return { formbuilderSubmission=formBuilderService.getFormBuilderSubmissionContextData() };
	}

}