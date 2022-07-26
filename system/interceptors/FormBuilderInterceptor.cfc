component extends="coldbox.system.Interceptor" {

	property name="formBuilderService" inject="delayedInjector:FormBuilderService";

	public void function configure() {}

	public void function onApplicationStart() {
		formBuilderService.updateUsesGlobalQuestions();
	}

	public void function preDeleteObjectData( event, interceptData ) {
		var objectName = interceptData.objectName ?: "";

		if ( objectName == "formbuilder_formsubmission" ) {
			if ( !isEmptyString( interceptData.id ?: "" ) ) {
				formBuilderService.deleteSubmissionResponses( submissionId=interceptData.id );
			}

			if ( StructKeyExists( interceptData, "filter" ) && !isEmptyString( interceptData.filter.form ?: "" ) ) {
				formBuilderService.deleteFormResponses( formId=interceptData.filter.form );
			}
		}
	}

}