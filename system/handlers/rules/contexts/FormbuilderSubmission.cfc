/**
 * Handler for the formbuilder submission rules engine context
 *
 */
component {

	property name="formBuilderService" inject="formBuilderService";

	private struct function getPayload() {
		return { formbuilderSubmission=formBuilderService.getFormBuilderSubmissionContextData() };
	}

}