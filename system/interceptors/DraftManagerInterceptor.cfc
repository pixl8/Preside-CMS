component extends="coldbox.system.Interceptor" {

	property name="draftManagerService" inject="delayedInjector:DraftManagerService";

	public void function configure() {}

	public void function postViewRecord( event, interceptData ) {
		var objectName = interceptData.objectName ?: "";

		if ( draftManagerService.isManagerEnabled( objectName=objectName ) ) {
			var recordId = interceptData.recordId ?: "";

			var draft = draftManagerService.getDraftData( objectName=objectName, recordId=recordId )

			prc.renderedRecord = renderView( view="admin/draftManager/_alert", args={
				  objectName  = objectName
				, objectTitle = prc.objectTitle
				, recordLink  = isEmptyString( draft.id ?: "" ) ? "" : event.buildAdminLink( objectName="draftmanager_draft", recordId=draft.id, operation="viewRecord" )
			} )
			& prc.renderedRecord;
		}
	}

	public void function postEditRecord( event, interceptData ) {
		var objectName = interceptData.objectName ?: "";

		if ( draftManagerService.isManagerEnabled( objectName=objectName ) ) {
			var recordId = interceptData.recordId ?: "";

			var draft = draftManagerService.getDraftData( objectName=objectName, recordId=recordId )

			prc.editRecordForm = renderView( view="admin/draftManager/_alert", args={
				  objectName  = objectName
				, objectTitle = prc.objectTitle
				, recordLink  = isEmptyString( draft.id ?: "" ) ? "" : event.buildAdminLink( objectName="draftmanager_draft", recordId=draft.id, operation="viewRecord" )
				, alertAction = "edit"
			} )

			& prc.editRecordForm;
		}
	}

}