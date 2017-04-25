/**
 * Handler for the formbuilder submission rules engine context
 *
 */
component {

	private struct function getPayload() {
		return { formbuilderSubmission = ( prc.formbuilderSubmission ?: {} ) };
	}

}