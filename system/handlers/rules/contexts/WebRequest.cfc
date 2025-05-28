component {

	property name="formBuilderService" inject="formBuilderService";

	private struct function getPayload() {
		var formId = rc.formBuilderFormSubmitted ?: "";

		if ( isEmptyString( formId ) ) {
			return {};
		}

		StructDelete( rc, "formBuilderFormSubmitted" );

		return { formbuilderSubmission={ id=formId, data=rc } };
	}

}