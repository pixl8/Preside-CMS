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
				formBuilderService.deleteSubmissionFiles( submissionId=interceptData.id );
			}
		}
	}

}