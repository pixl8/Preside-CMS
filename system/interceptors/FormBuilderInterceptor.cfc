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
				transaction {
					try {
						getPresideObject( "formbuilder_question_response" ).deleteData( filter={ submission_type="formbuilder", submission=interceptData.id } );
					} catch( database e ) { }
				}
			}

			var filter = interceptData.filter ?: {};

			if ( !isEmptyString( filter.form ?: "" ) ) {
				transaction {
					try {
						getPresideObject( "formbuilder_question_response" ).deleteData( filter={ submission_type="formbuilder", submission_reference=filter.form } );
					} catch( database e ) { }
				}
			}
		}
	}
}