component extends="preside.system.base.AdminHandler" {

	property name="presideObjectService"       inject="PresideObjectService";
	property name="datamanagerWorkflowService" inject="DatamanagerWorkflowService";
	property name="draftManagerService"        inject="DraftManagerService";

	public void function getDraftActionButtons( event, rc, prc, args={} ) {
		ArrayAppend( args.actions, {
			  type      = "button"
			, class     = "btn-info"
			, iconClass = "fa-save"
			, label     = translateResource( uri="draftManager:button.draft.title" )
			, name      = "_saveAction"
			, value     = "savedraft"
		} );
	}

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

}