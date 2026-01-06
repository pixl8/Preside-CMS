component extends="preside.system.base.AdminHandler" {

	property name="presideObjectService"            inject="PresideObjectService";
	property name="dataManagerService"              inject="DataManagerService";
	property name="dataManagerWorkflowService"      inject="DataManagerWorkflowService";
	property name="dataManagerCustomizationService" inject="DataManagerCustomizationService";
	property name="draftManagerService"             inject="DraftManagerService";
	property name="messageBox"                      inject="messagebox@cbmessagebox";
	property name="sessionStorage"                  inject="SessionStorage";

	public void function previewDraft( event, rc, prc ) {
		var redirectUrl = URLDecode( rc.redirect_url ?: "" );

		sessionStorage.setVar( name="_presideAdminShowNonLiveContent", value=true );

		setNextEvent( url=_validateRedirectUrl( redirectUrl=redirectUrl ) );
	}

	private void function preApproveAction( event, rc, prc, args={}, wfInstance ) {
		var recordId = _publishDraftRecordAction( argumentCollection=arguments, redirectOnSuccess=false );

		if ( !isEmptyString( local.recordId ?: "" ) ) {
			wfInstance.appendState( { _record_id=recordId } );
		}
	}

	private void function postApproveAction( event, rc, prc, args={}, wfInstance ) {
		var state       = wfInstance.getState();
		var objectName  = prc.record._object_name ?: "";
		var objectLabel = prc.record.label        ?: "";
		var recordId    = state._record_id        ?: "";

		messageBox.info( translateResource(
			  uri  = "draftManager:message.approve.description"
			, data = [
				  translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName )
				, '<a href="#event.buildAdminLink( objectName=objectName, operation="viewRecord", recordId=recordId )#">#objectLabel#</a>'
			  ]
		) );

		setNextEvent( url=event.buildAdminLink( objectName=objectName, operation="listing" ) );
	}

	private string function _publishDraftRecordAction( event, rc, prc, args={} ) {
		var objectName = prc.record._object_name ?: "";
		var recordId   = prc.record._record_id   ?: "";
		var draftId    = prc.record.id           ?: "";

		if ( !IsEmpty( prc.record._data ?: {} ) ) {
			StructAppend( rc, DeserializeJSON( prc.record._data ), true );
		}

		StructAppend( rc, {
			  _draft_id   = draftId
			, _saveAction = "publish"
		}, true );

		if ( isEmptyString( recordId ) ) {
			if ( dataManagerCustomizationService.objectHasCustomization( objectName, "addRecordAction" ) ) {
				recordId = dataManagerCustomizationService.runCustomization(
					  objectName = objectName
					, action     = "addRecordAction"
					, args       = { objectName=objectName }
				);
			} else {
				arguments.audit             = true;
				arguments.redirectOnSuccess = arguments.redirectOnSuccess ?: true;
				arguments.object            = objectName;

				recordId = runEvent(
					  event          = "admin.DataManager._addRecordAction"
					, prePostExempt  = true
					, private        = true
					, eventArguments = arguments
				);
			}
		} else {
			if ( dataManagerCustomizationService.objectHasCustomization( objectName, "editRecordAction" ) ) {
				dataManagerCustomizationService.runCustomization(
					  objectName = objectName
					, action     = "editRecordAction"
					, args       = { objectName=objectName, recordId=recordId }
				);
			} else {
				arguments.audit             = true;
				arguments.redirectOnSuccess = arguments.redirectOnSuccess ?: true;
				arguments.object            = objectName;
				arguments.recordId          = recordId;
				arguments.successUrl        = event.buildAdminLink( objectname=arguments.object, operation="listing" );

				runEvent(
					  event          = "admin.DataManager._editRecordAction"
					, prePostExempt  = true
					, private        = true
					, eventArguments = arguments
				);
			}
		}

		return recordId;
	}

	private void function _saveDraftRecordAction( event, rc, prc, args={} ) {
		var objectName = arguments.object   ?: "";
		var recordId   = arguments.recordId ?: "";
		var formData   = arguments.formData ?: {};

		var draftId = draftManagerService.saveDraftDataForObject( objectName=objectName, recordId=recordId, data=formData );

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

	private void function _rootBreadcrumb( event, rc, prc, args={} ) {
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:datamanager" )
			, link  = event.buildAdminLink( linkTo="datamanager" )
		);
	}

	private void function _objectBreadcrumb( event, rc, prc, args={} ) {
		var objectName    = prc.record._object_name ?: "draftmanager_draft";
		var objectURIRoot = presideObjectService.getResourceBundleUriRoot( objectName=objectName );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="#objectURIRoot#title", defaultValue=objectName )
			, link  = event.buildAdminLink( objectName=objectName, operation="listing" )
		);
	}

	private void function _recordBreadcrumb( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( objectName == "draftmanager_draft" ) {
			var recordId   = prc.record._record_id   ?: "";
			var objectName = prc.record._object_name ?: "";

			if ( !isEmptyString( recordId ) ) {
				args.recordLabel = renderLabel( objectName=objectName, recordId=recordId );
			}
		}

		runEvent(
			  event          = "admin.dataManager._recordBreadcrumb"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=args }
		);
	}

	private string function _getDraftTabContent( event, rc, prc, args={} ) {
		var tabId          = arguments.tabId      ?: "";
		var objectName     = arguments.objectName ?: "";
		var sortableFields = [];

		if ( tabId != "draft" ) {
			sortableFields = ListToArray( presideObjectService.getObjectAttribute(
				  objectName    = objectName
				, attributeName = "datamanagerSortableFields"
				, defaultValue  = ""
			) );

			if ( IsEmpty( sortableFields ) ) {
				sortableFields = dataManagerService.listGridFields( objectName );
			}

			ArrayDelete( sortableFields, "draftmanager_status" );
		}

		return runEvent(
			  event          = "admin.dataManager._objectListingViewlet"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args={
				  objectName     = tabId == "draft" ? "draftmanager_draft" : objectName
				, sortableFields = sortableFields
			} }
		);
	}

	private array function _getEditRecordActionButtons( event, rc, prc, args={} ) {
		// Override to resuse save draft button.
		args.draftsEnabled = true;
		args.canSaveDraft  = true;
		args.canPublish    = true;
		args.cancelAction  = event.buildAdminLink( objectName=( prc.record._object_name ?: "" ), operation="listing", queryString="tab=draft" );

		return runEvent(
			  event          = "admin.DataManager._getEditRecordActionButtons"
			, private        = true
			, prepostExempt  = true
			, eventArguments = arguments
		);
	}

	private array function _getDraftPreviewActionButtons( event, rc, prc, args={} ) {
		return [];
	}

	private string function _validateRedirectUrl(
		required string redirectUrl
	) {
		if ( !REFindNoCase( "^https?://", arguments.redirectUrl ) ) {
			return getRequestContext().buildLink( page="homepage" );
		}

		var domain = REReplace( ListFirst( arguments.redirectUrl, "?&" ), "^https?://([^/]+).*$", "\1" );

		if ( !Len( domain ) ) {
			return getRequestContext().buildLink( page="homepage" );
		}

		if ( domain == ( getRequestContext().getServerName() & getRequestContext().getPortSuffix() ) ) {
			return arguments.redirectUrl;
		}

		return getRequestContext().buildLink( page="homepage" );
	}

}