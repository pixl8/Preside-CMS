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

		var labelName = presideObjectService.getLabelField( objectName=objectName );

		if ( isEmptyString( labelName ) ) {
			throw( type="PresideObjectService.no.label.field", message="The object [#objectName#] has no label field." );
		}

		var label = formData[ labelName ] ?: "";

		if ( isEmptyString( label ) ) {
			label = CreateUUID();
		}

		var draftId = getPresideObject( "draftmanager_draft" ).insertData(
			data       = {
				  label       = label
				, object_name = objectName
				, data        = SerializeJSON( formData )
			}
		);
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

}