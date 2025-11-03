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

		var draftId = getPresideObject( "draftmanager_draft" ).insertData(
			data = {
				  label       = _getDraftLabel( objectName=objectName, formData=formData )
				, object_name = objectName
				, record_id   = ""
				, workflow_id = draftManagerService.getWorkflowId( objectName=objectName )
				, data        = SerializeJSON( formData )
			}
		);

		setNextEvent( url=event.buildAdminLink( objectName="draftmanager_draft", operation="viewRecord", recordId=draftId ) );
	}

	public void function editDraftRecordAction( event, rc, prc, args={} ) {
		if ( !draftManagerService.isDraftAction() ) {
			return;
		}

		var objectName = arguments.object   ?: "";
		var formData   = arguments.formData ?: {};

		var draftId = args.recordId ?: "";

		getPresideObject( "draftmanager_draft" ).updateData(
			  id   = draftId
			, data = {
				  label = _getDraftLabel( objectName=objectName, formData=formData )
				, data  = SerializeJSON( formData )
			  }
		);

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

		messageBox.info( translateResource(
			  uri  = "cms:datamanager.recordAdded.confirmation"
			, data = [
				  translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName )
				, '<a href="#event.buildAdminLink( objectName=objectName, operation="viewRecord", recordId=recordId )#">#event.getValue( name=labelField, defaultValue=translateResource( uri="cms:datamanager.record" ) )#</a>'
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
		, required struct formData
	) {
		var labelName = presideObjectService.getLabelField( objectName=arguments.objectName );

		if ( isEmptyString( labelName ) ) {
			throw( type="PresideObjectService.no.label.field", message="The object [#arguments.objectName#] has no label field." );
		}

		var label = arguments.formData[ labelName ] ?: "";

		if ( isEmptyString( label ) ) {
			label = CreateUUID();
		}

		return label;
	}

}