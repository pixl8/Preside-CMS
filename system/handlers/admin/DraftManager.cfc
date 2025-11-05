component extends="preside.system.base.AdminHandler" {

	property name="presideObjectService"            inject="PresideObjectService";
	property name="dataManagerWorkflowService"      inject="DataManagerWorkflowService";
	property name="dataManagerCustomizationService" inject="DataManagerCustomizationService";
	property name="draftManagerService"             inject="DraftManagerService";
	property name="messageBox"                      inject="messagebox@cbmessagebox";

	public void function addDraftRecordAction( event, rc, prc, args={} ) {
		if ( !draftManagerService.isDraftAction() ) {
			return;
		}

		var objectName = arguments.object   ?: "";
		var formData   = arguments.formData ?: {};
		var label      = _getDraftLabel( objectName=objectName, data=formData );

		var draftId = getPresideObject( "draftmanager_draft" ).insertData(
			data = {
				  label       = label
				, object_name = objectName
				, record_id   = ""
				, workflow_id = draftManagerService.getWorkflowId( objectName=objectName )
				, data        = SerializeJSON( formData )
			}
		);

		messageBox.info( translateResource(
			  uri  = "draftManager:message.add.description"
			, data = [
				  translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName )
				, '<a href="#event.buildAdminLink( objectName="draftmanager_draft", operation="viewRecord", recordId=draftId )#">#label#</a>'
			  ]
		) );

		setNextEvent( url=event.buildAdminLink( objectName="draftmanager_draft", operation="viewRecord", recordId=draftId ) );
	}

	public void function editDraftRecordAction( event, rc, prc, args={} ) {
		if ( !draftManagerService.isDraftAction() ) {
			return;
		}

		var objectName = arguments.object   ?: "";
		var formData   = arguments.formData ?: {};
		var label      = _getDraftLabel( objectName=objectName, data=formData );

		var draftId = args.recordId ?: "";

		getPresideObject( "draftmanager_draft" ).updateData(
			  id   = draftId
			, data = {
				  label = label
				, data  = SerializeJSON( formData )
			  }
		);

		messageBox.info( translateResource(
			  uri  = "draftManager:message.edit.description"
			, data = [
				  translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName )
				, '<a href="#event.buildAdminLink( objectName="draftmanager_draft", operation="viewRecord", recordId=draftId )#">#label#</a>'
			  ]
		) );

		setNextEvent( url=event.buildAdminLink( objectName="draftmanager_draft", operation="viewRecord", recordId=draftId ) );
	}

	private void function preApproveAction( event, rc, prc, args={}, wfInstance ) {
		prc.objectName = rc.object = arguments.object = prc.record.object_name ?: "";

		if ( !IsEmpty( prc.record.data ?: {} ) ) {
			StructAppend( rc, DeserializeJSON( prc.record.data ), true );
		}

		var recordId = _addDraftRecordAction( argumentCollection=arguments );

		if ( !isEmptyString( recordId ) ) {
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

	public string function _addDraftRecordAction( event, rc, prc ) {
		var objectName = args.objectName ?: ( prc.objectName ?: "" );

		if ( dataManagerCustomizationService.objectHasCustomization( objectName, "addRecordAction" ) ) {
			return dataManagerCustomizationService.runCustomization(
				  objectName = objectName
				, action     = "addRecordAction"
				, args       = { objectName=objectName }
			);
		} else {
			arguments.redirectOnSuccess = false;
			arguments.audit             = true;

			return runEvent(
				  event          = "admin.DataManager._addRecordAction"
				, prePostExempt  = true
				, private        = true
				, eventArguments = arguments
			);
		}
	}

	private array function _getAddRecordActionButtons( event, rc, prc, args={} ) {
		// Override to resuse save draft button.
		args.draftsEnabled = true;
		args.canSaveDraft  = true;

		return runEvent(
			  event          = "admin.DataManager._getAddRecordActionButtons"
			, private        = true
			, prepostExempt  = true
			, eventArguments = arguments
		);
	}

	private array function _getEditRecordActionButtons( event, rc, prc, args={} ) {
		// Override to resuse save draft button.
		args.draftsEnabled = true;
		args.canSaveDraft  = true;
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