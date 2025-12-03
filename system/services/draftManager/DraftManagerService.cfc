/**
 * @singleton      true
 * @presideservice true
 */
component {

	property name="presideObjectService"            inject="delayedInjector:PresideObjectService";
	property name="dataManagerWorkflowService"      inject="delayedInjector:DataManagerWorkflowService";
	property name="dataManagerCustomizationService" inject="delayedInjector:DataManagerCustomizationService";

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

	public struct function getDraftForObject(
		  required string objectName
		,          string recordId = ""
		,          string draftid  = ""
	) {
		if ( !$isFeatureEnabled( "draftManager" ) ) {
			return {};
		}

		var filter = [ "_object_name = :_object_name and _status != 'publish'" ];

		if ( !$helpers.isEmptyString( arguments.recordId ) ) {
			ArrayAppend( filter, "_record_id = :_record_id" );
		}

		if ( !$helpers.isEmptyString( arguments.draftid ) ) {
			ArrayAppend( filter, "id = :id" );
		}

		return $getPresideObject( "draftmanager_draft" ).selectData(
			  argumentCollection = arguments
			, filter             = ArrayToList( filter, " and " )
			, filterParams       = {
				  _object_name = { type="cf_sql_varchar", value=arguments.objectName }
				, _record_id   = { type="cf_sql_varchar", value=arguments.recordId  }
				, id           = { type="cf_sql_varchar", value=arguments.draftId  }
			  }
			, returnType         = "singleRecordStruct"
		);
	}

	public struct function getDraftDataForObject(
		  required string objectName
		,          string recordId = ""
		,          string draftid  = ""
	) {
		if ( !$isFeatureEnabled( "draftManager" ) ) {
			return {};
		}

		var draft = getDraftForObject( argumentCollection=arguments );

		return IsEmpty( draft._data ?: "" ) ? {} : DeserializeJSON( draft._data );
	}

	public string function saveDraftDataForObject(
		  required string objectName
		,          string recordId = ""
		,          struct data     = {}
	) {
		var draft = $getPresideObject( "draftmanager_draft" ).selectData(
			  selectFields = [ "id" ]
			, filter       = "_object_name = :_object_name and _record_id = :_record_id and _status != 'publish'"
			, filterParams = {
				  _object_name = { type="cf_sql_varchar", value=arguments.objectName }
				, _record_id   = { type="cf_sql_varchar", value=arguments.recordId   }
			  }
		);

		var label = getDraftLabel( objectName=arguments.objectName, data=arguments.data );

		if ( $helpers.isEmptyString( draft.id ?: "" ) ) {
			return $getPresideObject( "draftmanager_draft" ).insertData(
				data = {
					  label                   = label
					, _object_name            = arguments.objectName
					, _record_id              = arguments.recordId
					, _workflow_id            = getWorkflowId( objectName=arguments.objectName )
					, _data                   = SerializeJSON( arguments.data )
					, _security_user_created  = $getAdminLoggedInUserId()
					, _security_user_modified = $getAdminLoggedInUserId()
				}
			);
		} else {
			$getPresideObject( "draftmanager_draft" ).updateData(
				  id   = draft.id
				, data = {
					  label                   = label
					, _data                   = SerializeJSON( arguments.data )
					, _security_user_modified = $getAdminLoggedInUserId()
				  }
			);

			return draft.id;
		}
	}

	private string function getDraftLabel(
		  required string objectName
		,          struct data = {}
	) {
		if ( dataManagerCustomizationService.objectHasCustomization( objectName=arguments.objectName, action="getDraftLabel" ) ) {
			return dataManagerCustomizationService.runCustomization(
				  objectName     = arguments.objectName
				, action         = "getDraftLabel"
				, args           = arguments
			);
		}

		var labelName = presideObjectService.getLabelField( objectName=arguments.objectName );

		if ( $helpers.isEmptyString( labelName ) ) {
			throw( type="PresideObjectService.no.label.field", message="The object [#arguments.objectName#] has no label field." );
		}

		return arguments.data[ labelName ] ?: "";
	}

}