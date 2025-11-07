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

	public struct function getDraftData(
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

	public string function saveDraftData(
		  required string objectName
		,          string recordId = ""
		,          struct data     = {}
	) {
		var draft = $getPresideObject( "draftmanager_draft" ).selectData(
			  selectFields = [ "id" ]
			, filter       = "object_name = :object_name and record_id = :record_id and _status != 'publish'"
			, filterParams = {
				  object_name = arguments.objectName
				, record_id   = arguments.recordId
			  }
		);

		var label = getDraftLabel( objectName=arguments.objectName, data=arguments.data );

		if ( $helpers.isEmptyString( draft.id ?: "" ) ) {
			return $getPresideObject( "draftmanager_draft" ).insertData(
				data = {
					  label       = label
					, object_name = arguments.objectName
					, record_id   = arguments.recordId
					, workflow_id = getWorkflowId( objectName=arguments.objectName )
					, data        = SerializeJSON( arguments.data )
				}
			);
		} else {
			$getPresideObject( "draftmanager_draft" ).updateData(
				  id   = draft.id
				, data = {
					  label = label
					, data  = SerializeJSON( arguments.data )
				  }
			);

			return draft.id;
		}
	}

	private string function getDraftLabel(
		  required string objectName
		, required struct data
	) {
		var labelName = presideObjectService.getLabelField( objectName=arguments.objectName );

		if ( $helpers.isEmptyString( labelName ) ) {
			throw( type="PresideObjectService.no.label.field", message="The object [#arguments.objectName#] has no label field." );
		}

		return arguments.data[ labelName ] ?: "";
	}

}