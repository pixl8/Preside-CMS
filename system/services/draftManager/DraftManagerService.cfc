/**
 * @singleton      true
 * @presideservice true
 */
component {

	property name="presideObjectService"       inject="PresideObjectService";
	property name="dataManagerWorkflowService" inject="DataManagerWorkflowService";

	public any function init() {
		return this;
	}

	public boolean function isManagerEnabled( required string objectName ) {
		if ( !$isFeatureEnabled( "draftManager" ) ) {
			return false;
		}

		return presideObjectService.getObjectAttribute( objectName=arguments.objectName, attributeName="draftManagerEnabled", defaultValue=false );
	}

	public boolean function isDraftAction() {
		if ( !$isFeatureEnabled( "draftManager" ) ) {
			return false;
		}

		var rc = $getRequestContext().getCollection();

		return ( rc._saveaction ?: "" ) == "savedraft";
	}

	public string function getWorkflowId(
		  required string objectName
		,          string recordId = ""
	) {
		var workflowHandler = "admin.DataManager.#objectName#.getWorkflowForRecord";

		if ( $getColdbox().handlerExists( workflowHandler ) ) {
			var result = $runEvent(
				  event          = workflowHandler
				, private        = true
				, prepostExempt  = true
				, eventArguments = { recordId=arguments.recordId }
			);

			return local.result ?: "";
		}

		return dataManagerWorkflowService.getDefaultWorkflowId( objectName="draftmanager_draft" );
	}

	public struct function getDraftForRecord(
		  required string objectName
		, required string recordId
	) {
		if ( !$isFeatureEnabled( "draftManager" ) ) {
			return false;
		}

		return $getPresideObject( "draftmanager_draft" ).selectData(
			  filter       = "object_name = :object_name and record_id = :record_id and _status != 'publish'"
			, filterParams = {
				  object_name = arguments.objectName
				, record_id   = arguments.recordId
			  }
			, returnType   = "singleRecordStruct"
		);
	}

}