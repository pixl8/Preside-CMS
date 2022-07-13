component extends="coldbox.system.Interceptor" {
	property name="formBuilderService"          inject="delayedInjector:FormBuilderService";
	property name="formBuilderStorageProvider"  inject="delayedInjector:FormBuilderStorageProvider";
	property name="formbuilderItemTypesService" inject="delayedInjector:FormbuilderItemTypesService";

	public void function configure() {}

	public void function onApplicationStart() {
		formBuilderService.updateUsesGlobalQuestions();
	}

	public void function preDeleteObjectData( event, interceptData ) {
		var objectName = interceptData.objectName ?: "";

		if ( objectName == "formbuilder_formsubmission" ) {
			var extraFilters = [];

			if ( !isEmptyString( interceptData.id ?: "" ) ) {
				var submission = formBuilderService.getSubmission( submissionId=interceptData.id );

				if ( formBuilderService.isV2Form( submission.form ?: "" ) ) {
					ArrayAppend( extraFilters, { filter={ submission=interceptData.id } } );
				}
			}

			if ( StructKeyExists( interceptData, "filter" ) && !isEmptyString( interceptData.filter.form ?: "" ) ) {

				if ( formBuilderService.isV2Form( interceptData.filter.form ) ) {
					ArrayAppend( extraFilters, { filter={ submission_reference=interceptData.filter.form } } );
				}
			}

			if ( ArrayLen( extraFilters ) ) {
				var filePaths = getPresideObject( "formbuilder_question_response" ).selectData(
					  selectFields = [ "response" ]
					, filter       = "submission_type = 'formbuilder' and question.item_type in ( :question.item_type )"
					, filterParams = {
						"question.item_type" = formbuilderItemTypesService.getFileUploadItemTypes()
					  }
					, extraFilters = extraFilters
				);

				for ( var filePath in filePaths ) {
					formBuilderStorageProvider.deleteObject( path=filePath.response, private=true );
				}

				getPresideObject( "formbuilder_question_response" ).deleteData(
					  filter       = { submission_type="formbuilder" }
					, extraFilters = extraFilters
				);
			}
		}
	}
}