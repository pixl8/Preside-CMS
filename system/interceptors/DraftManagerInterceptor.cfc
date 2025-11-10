component extends="coldbox.system.Interceptor" {

	property name="draftManagerService" inject="delayedInjector:DraftManagerService";

	public void function configure() {}

	public void function postViewRecord( event, interceptData ) {
		var objectName = interceptData.objectName ?: "";

		if ( draftManagerService.isManagerEnabled( objectName=objectName ) ) {
			var recordId = interceptData.recordId ?: "";

			prc.renderedRecord = _getDraftAlert( objectName=objectName, objectTitle=prc.objectTitle, recordId=recordId ) & prc.renderedRecord;
		}
	}

	public void function postEditRecord( event, interceptData ) {
		var objectName = interceptData.objectName ?: "";

		if ( draftManagerService.isManagerEnabled( objectName=objectName ) ) {
			var recordId = interceptData.recordId ?: "";

			prc.editRecordForm = _getDraftAlert( objectName=objectName, objectTitle=prc.objectTitle, recordId=recordId, alertAction="edit" ) & prc.editRecordForm;
		}
	}

	private string function _getDraftAlert(
		  required string objectName
		, required string objectTitle
		, required string recordId
		,          string alertAction = "view"
	) {
		var draft = draftManagerService.getDraftData( objectName=arguments.objectName, recordId=arguments.recordId );

		return renderView( view="admin/draftManager/_alert", args={
			  objectName  = arguments.objectName
			, objectTitle = arguments.objectTitle
			, recordLink  = isEmptyString( draft.id ?: "" ) ? "" : getRequestContext().buildAdminLink( objectName="draftmanager_draft", recordId=draft.id, operation="viewRecord" )
			, alertAction = arguments.alertAction
		} );
	}

}