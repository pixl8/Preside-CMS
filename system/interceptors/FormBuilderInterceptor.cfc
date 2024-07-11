component extends="coldbox.system.Interceptor" {
	property name="formBuilderService" inject="delayedInjector:FormBuilderService";

	public void function configure() {}

	public void function onApplicationStart() {
		if ( isFeatureEnabled( "formbuilder2" ) ) {
			formBuilderService.updateUsesGlobalQuestions();
		}
	}

	public void function preDeleteObjectData( event, interceptData ) {
		var objectName = interceptData.objectName ?: "";

		if ( objectName == "formbuilder_formsubmission" ) {
			var filter = interceptData.filter ?: {};
			var id     = interceptData.id     ?: ( filter.id ?: "" );

			if ( isArray( id ) ) {
				id = ArrayFirst( id );
			}

			if ( !isEmptyString( id ) ) {
				formBuilderService.deleteSubmissionResponses( submissionId=id );
				return;
			}

			if ( !StructIsEmpty( filter ) ) {
				formBuilderService.deleteFormResponses( filter=filter );
			}
		}
	}
}