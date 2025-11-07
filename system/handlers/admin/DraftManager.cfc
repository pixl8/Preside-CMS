component extends="preside.system.base.AdminHandler" {

	property name="presideObjectService"            inject="PresideObjectService";
	property name="dataManagerWorkflowService"      inject="DataManagerWorkflowService";
	property name="dataManagerCustomizationService" inject="DataManagerCustomizationService";
	property name="draftManagerService"             inject="DraftManagerService";
	property name="messageBox"                      inject="messagebox@cbmessagebox";

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

		var objectName  = prc.record.object_name ?: "";
		var objectLabel = prc.record.label ?: "";
		var recordId    = state.record_id        ?: "";

		messageBox.info( translateResource(
			  uri  = "draftManager:message.approve.description"
			, data = [
				  translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName )
				, '<a href="#event.buildAdminLink( objectName=objectName, operation="viewRecord", recordId=recordId )#">#objectLabel#</a>'
			  ]
		) );

		setNextEvent( url=event.buildAdminLink( objectName=objectName, operation="listing" ) );
	}

	private void function _saveDraftRecordAction( event, rc, prc, args={} ) {
		var objectName = arguments.object   ?: "";
		var recordId   = arguments.recordId ?: "";
		var formData   = arguments.formData ?: {};

		var draftId = draftManagerService.saveDraftData( objectName=objectName, recordId=recordId, data=formData );

		messageBox.info( translateResource(
			  uri  = "draftManager:message.edit.description"
			, data = [
				  translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName )
				, '<a href="#event.buildAdminLink( objectName="draftmanager_draft", operation="viewRecord", recordId=draftId )#">#renderLabel( objectName="draftmanager_draft", recordId=draftId )#</a>'
			  ]
		) );

		setNextEvent( url=event.buildAdminLink( objectName="draftmanager_draft", operation="viewRecord", recordId=draftId ) );
	}

	private string function _getDraftTabs( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var i18nBase   = "preside-objects.#objectName#:";

		args.tabs = args.tabs ?: [ "default", "draft" ];

		for ( var i=1; i<=ArrayLen( args.tabs ); i++ ) {
			var tabId = args.tabs[ i ];

			args.tabs[ i ] = {
				  id        = tabId
				, iconClass = translateResource( uri="#i18nBase#:viewtab.#tabId#.iconClass", defaultValue=translateResource( uri="draftManager:viewtab.#tabId#.iconClass", defaultValue=tabId ) )
				, content   = _getDraftTabContent( argumentCollection=arguments, tabId=tabId, objectName=objectName )
				, title     = translateResource( uri="#i18nBase#:viewtab.#tabId#.title", defaultValue=translateResource( uri="draftManager:viewtab.#tabId#.title", defaultValue=tabId ) )
			};
		}

		if ( ArrayLen( args.tabs ) ) {
			event.include( "/css/admin/specific/datamanager/viewtabs/" );

			return renderView( view="/admin/datamanager/_tabs", args=args );
		}

		return "";
	}

	private string function _getDraftTabContent( event, rc, prc, args={} ) {
		var tabId      = arguments.tabId      ?: "";
		var objectName = arguments.objectName ?: "";

		return runEvent(
			  event          = "admin.dataManager._objectListingViewlet"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args={
				  object_name = objectName
				, objectName  = tabId == "draft" ? "draftmanager_draft" : objectName
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

}