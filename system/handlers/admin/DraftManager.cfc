component extends="preside.system.base.AdminHandler" {

	property name="presideObjectService"       inject="PresideObjectService";
	property name="datamanagerWorkflowService" inject="DatamanagerWorkflowService";
	property name="draftManagerService"        inject="DraftManagerService";

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
			  id   = args.recordId
			, data = {
				  label = _getDraftLabel( objectName=objectName, formData=formData )
				, data  = SerializeJSON( formData )
			  }
		);

		setNextEvent( url=event.buildAdminLink( objectName="draftmanager_draft", operation="viewRecord", recordId=draftId ) );
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