component extends="preside.system.base.AdminHandler" {

	property name="presideObjectService"            inject="PresideObjectService";
	property name="dataManagerWorkflowService"      inject="DataManagerWorkflowService";
	property name="dataManagerCustomizationService" inject="DataManagerCustomizationService";
	property name="draftManagerService"             inject="DraftManagerService";
	property name="messageBox"                      inject="messagebox@cbmessagebox";

	private void function _saveDraftRecordAction( event, rc, prc, args={} ) {
		var objectName = arguments.object   ?: "";
		var recordId   = arguments.recordId ?: "";
		var formData   = arguments.formData ?: {};

		var draftId = _saveDraftData( objectName=objectName, data=formData, recordId=recordId );

		messageBox.info( translateResource(
			  uri  = "draftManager:message.edit.description"
			, data = [
				  translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName )
				, '<a href="#event.buildAdminLink( objectName="draftmanager_draft", operation="viewRecord", recordId=draftId )#">#renderLabel( objectName="draftmanager_draft", recordId=draftId )#</a>'
			  ]
		) );

		setNextEvent( url=event.buildAdminLink( objectName="draftmanager_draft", operation="viewRecord", recordId=draftId ) );
	}

	private string function _saveDraftData(
		  required string objectName
		,          struct data     = {}
		,          string recordId = ""
	) {
		var draft = getPresideObject( "draftmanager_draft" ).selectData(
			  selectFields = [ "id" ]
			, filter       = "object_name = :object_name and record_id = :record_id and _status != 'publish'"
			, filterParams = {
				  object_name = arguments.objectName
				, record_id   = arguments.recordId
			  }
		);

		var label = _getDraftLabel( objectName=arguments.objectName, data=arguments.data );

		if ( isEmptyString( draft.id ?: "" ) ) {
			return getPresideObject( "draftmanager_draft" ).insertData(
				data = {
					  label       = label
					, object_name = arguments.objectName
					, record_id   = arguments.recordId
					, workflow_id = draftManagerService.getWorkflowId( objectName=arguments.objectName )
					, data        = SerializeJSON( arguments.data )
				}
			);
		} else {
			getPresideObject( "draftmanager_draft" ).updateData(
				  id   = draft.id
				, data = {
					  label = label
					, data  = SerializeJSON( arguments.data )
				  }
			);

			return draft.id;
		}
	}

	private void function preApproveAction( event, rc, prc, args={}, wfInstance ) {
		prc.objectName = rc.object = arguments.object = prc.record.object_name ?: "";

		if ( !IsEmpty( prc.record.data ?: {} ) ) {
			StructAppend( rc, DeserializeJSON( prc.record.data ), true );
		}

		if ( dataManagerCustomizationService.objectHasCustomization( prc.objectName, "addRecordAction" ) ) {
			recordId = dataManagerCustomizationService.runCustomization(
				  objectName = prc.objectName
				, action     = "addRecordAction"
				, args       = { objectName=prc.objectName }
			);
		} else {
			arguments.redirectOnSuccess = false;
			arguments.audit             = true;

			recordId = runEvent(
				  event          = "admin.DataManager._addRecordAction"
				, prePostExempt  = true
				, private        = true
				, eventArguments = arguments
			);
		}

		if ( !isEmptyString( local.recordId ?: "" ) ) {
			wfInstance.appendState( { record_id=recordId } );
		}
	}

	private void function postApproveAction( event, rc, prc, args={}, wfInstance ) {
		var state = wfInstance.getState();

		var objectName = prc.record.object_name ?: "";
		var recordId   = state.record_id        ?: "";
		var labelField = presideObjectService.getObjectAttribute( objectName, "labelfield", "label" );
		var label      = _getDraftLabel( objectName=objectName, data=rc );

		messageBox.info( translateResource(
			  uri  = "draftManager:message.approve.description"
			, data = [
				  translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName )
				, '<a href="#event.buildAdminLink( objectName=objectName, operation="viewRecord", recordId=recordId )#">#label#</a>'
			  ]
		) );

		setNextEvent( url=event.buildAdminLink( objectName=objectName, operation="listing" ) );
	}

	private string function _getObjectListing( event, rc, prc, args={} ) {
		return runEvent(
			  event          = "admin.DataManager._objectListingViewlet"
			, private        = true
			, prePostExempt  = true
			, eventArguments = arguments
		);
	}

	private string function _getDraftListing( event, rc, prc, args={} ) {
		return runEvent(
			  event          = "admin.dataManager._objectListingViewlet"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args={
				  object_name = args.objectName
				, objectName  = "draftmanager_draft"
			} }
		);
	}

	private array function _getEditRecordActionButtons( event, rc, prc, args={} ) {
		// Override to resuse save draft button.
		args.draftsEnabled = true;
		args.canSaveDraft  = true;
		args.canPublish    = true;
		args.cancelAction  = event.buildAdminLink( objectName=( prc.record.object_name ?: "" ), operation="listing", queryString="tab=draft" );

		return runEvent(
			  event          = "admin.DataManager._getEditRecordActionButtons"
			, private        = true
			, prepostExempt  = true
			, eventArguments = arguments
		);
	}

	private string function _getDraftLabel(
		  required string objectName
		, required struct data
	) {
		var labelName = presideObjectService.getLabelField( objectName=arguments.objectName );

		if ( isEmptyString( labelName ) ) {
			throw( type="PresideObjectService.no.label.field", message="The object [#arguments.objectName#] has no label field." );
		}

		return arguments.data[ labelName ] ?: "";
	}

}