component {

	property name="datamanagerWorkflowService" inject="DatamanagerWorkflowService";

	public string function default( event, rc, prc, args={} ) {
		var id = args.data ?: "";

		if ( !isEmptyString( id ) ) {
			var record = getPresideObject( "draftmanager_draft" ).selectData( id=id, selectFields=[ "workflow_id" ] );

			if ( record.recordCount ) {
				return datamanagerWorkflowService.renderStatus( objectName="draftmanager_draft", recordId=id, workflowId=record.workflow_id );
			}
		}

		return "";
	}

}