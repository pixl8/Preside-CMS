component extends="preside.system.base.EnhancedDataManagerBase" {

	property name="presideObjectService"            inject="PresideObjectService";
	property name="dataManagerService"              inject="DataManagerService";
	property name="draftManagerService"             inject="DraftManagerService";
	property name="dataManagerCustomizationService" inject="DataManagerCustomizationService";
	property name="dataManagerWorkflowService"      inject="DataManagerWorkflowService";

	variables.infoCol3 = [];
	variables.tabs     = [ "draft" ];

	private void function rootBreadcrumb( event, rc, prc, args={} ) {
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:datamanager" )
			, link  = event.buildAdminLink( linkTo="datamanager" )
		);
	}

	private void function objectBreadcrumb( event, rc, prc, args={} ) {
		var objectName    = prc.record._object_name ?: "draftmanager_draft";
		var objectURIRoot = presideObjectService.getResourceBundleUriRoot( objectName=objectName );

		event.addAdminBreadCrumb(
			  title = prc.objectTitlePlural
			, link  = event.buildAdminLink( objectName=objectName, operation="listing" )
		);
	}

	private void function recordBreadcrumb( event, rc, prc, args={} ) {
		var objectName = prc.record._object_name ?: "";
		var recordId   = prc.record.id           ?: "";

		if ( dataManagerService.isOperationAllowed( objectName=objectName, operation="read" ) ) {
			event.addAdminBreadCrumb(
				  title = prc.recordLabel
				, link  = event.buildAdminLink( objectName="draftmanager_draft", recordId=recordId, operation="viewRecord" )
			);
		}
	}

	private string function _draftTab( event, rc, prc, args={} ) {
		args.objectName = prc.record._object_name ?: "";
		args.recordId   = prc.record._record_id   ?: "";

		if ( !IsEmpty( args.record._data ?: "" ) ) {
			var data = DeserializeJSON( args.record._data );

			data.draftmanager_status                 = args.record._status;
			data.draftmanager_datecreated            = args.record.datecreated;
			data.draftmanager_datemodified           = args.record.datemodified;
			data.draftmanager_security_user_created  = args.record._security_user_created;
			data.draftmanager_security_user_modified = args.record._security_user_modified;

			if ( isEmptyString( args.recordId ) ) {
				data.datecreated  = "";
				data.datemodified = "";
			} else {
				var record = getPresideObject( args.objectName ).selectData(
					  id           = args.recordId
					, selectFields = [ "datecreated", "datemodified" ]
				);

				data.datecreated  = record.datecreated  ?: "";
				data.datemodified = record.datemodified ?: "";
			}

			StructAppend( args.record, data, true );

			prc.record = args.record;

			return runEvent(
				  event          = "admin.DataHelpers.viewRecord"
				, private        = true
				, prepostExempt  = true
				, eventArguments = arguments
			);
		}

		return "";
	}

	private string function _workflowTab( event, rc, prc, args={} ) {
		args.objectName = "draftmanager_draft";

		return super._workflowTab( argumentCollection=arguments );
	}

	private string function _workflowTabTitle( event, rc, prc, args={} ) {
		args.objectName = "draftmanager_draft";

		return super._workflowTabTitle( argumentCollection=arguments );
	}

	private array function getTopRightButtonsForViewRecord() {
		var objectName   = "draftmanager_draft";
		var objectTitle  = prc.objectTitle ?: "";
		var recordId     = prc.recordId    ?: "";
		var recordLabel  = prc.recordLabel ?: "";
		var language     = rc.language     ?: "";
		var actions      = [];
		var children     = [];

		if ( IsTrue( prc.canView ?: "" ) ) {
			var sourceObjectName = prc.record._object_name ?: "";
			var sourceRecordId   = prc.record._record_id   ?: "";

			var previewAction = customizationService.runCustomization(
				  objectName = sourceObjectName
				, action     = "getPreviewActionButton"
				, defaultHandler = "admin.DraftManager.getPreviewActionButton"
				, args       = {
					  objectName = sourceObjectName
					, recordId   = sourceRecordId
					, draftId    = recordId
				}
			);

			if ( !IsEmpty( previewAction ) ) {
				ArrayPrepend( actions, previewAction );
			}
		}

		if ( IsTrue( prc.canDelete ?: "" ) ) {
			if ( ArrayLen( children ) ) {
				ArrayAppend( children, "---" );
			}

			ArrayAppend( children, {
				  title     = translateResource( uri="draftManager:action.delete.title" )
				, icon      = translateResource( uri="draftManager:action.delete.iconClass" )
				, link      = event.buildAdminLink( objectName=objectName, operation="deleteRecordAction", recordId=recordId )
				, globalKey = "d"
				, prompt    = translateResource( uri="cms:datamanager.deleteRecord.prompt", data=[ objectTitle, stripTags( recordLabel ) ] )
				, match     = dataManagerService.useTypedConfirmationForDeletion( objectName ) ? datamanagerService.getDeletionConfirmationMatch( objectName, record ) : ""
				, id        = "delete"
			} );
		}

		if ( isTrue( prc.canEdit ?: "" ) ) {
			ArrayAppend( actions, {
				  title     = translateResource( uri="draftManager:action.edit.title" )
				, iconClass = translateResource( uri="draftManager:action.edit.iconClass" )
				, link      = event.buildAdminLink( objectName=objectName, operation="editRecord", recordId=recordId )
				, btnClass  = "btn-primary-default"
				, globalKey = "e"
				, children  = children
				, id        = "actionButtons"
			} );
		} else if ( ArrayLen( children ) ) {
			ArrayAppend( actions, {
				  title     = translateResource( uri="draftManager:action.default.title" )
				, iconClass = translateResource( uri="draftManager:action.defauilt.iconClass" )
				, btnClass  = "btn-primary-default"
				, children  = children
				, id        = "actionButtons"
			} );
		}

		customizationService.runCustomization(
			  objectName     = objectName
			, action         = "extraTopRightButtonsForViewRecord"
			, args           = { objectName=objectName, actions=actions }
		);

		announceInterception( "postExtraTopRightButtonsForViewRecord", { objectName=objectName, actions=actions } );

		return actions;
	}

	private string function preViewRecordContent( event, rc, prc, args={} ) {
		var objectName    = prc.record._object_name ?: "";
		var recordId      = prc.record._record_id   ?: "";
		var objectURIRoot = presideObjectService.getResourceBundleUriRoot( objectName=objectName );

		prc.recordLabel = prc.record.label ?: "";
		prc.pageTitle   = prc.recordLabel;
		prc.pageIcon    = translateResource( uri="#objectURIRoot#iconClass", defaultValue="fa-database" );

		return renderView( view="admin/draftManager/_alert", args={
			  objectName  = prc.objectName
			, objectTitle = translateResource( uri="#objectURIRoot#title.singular", defaultValue=objectName )
			, recordLink  = isEmptyString( args.record._record_id ?: "" ) ? "" : event.buildAdminLink( objectName=args.record._object_name, recordId=args.record._record_id, operation="viewRecord" )
		} );
	}

	private void function getListingHeaderFields( event, rc, prc, args={} ) {
		var objectName = prc.objectName ?: "";
		var labelName  = presideObjectService.getLabelField( objectName=objectName );

		args.gridHeaderLabels[ "label" ] = translateResource( uri="preside-objects.#objectName#:field.#labelName#.listing.title", defaultValue=translateResource( uri="preside-objects.#objectName#:field.#labelName#.title", defaultValue=labelName ) );
	}

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		var objectName  = prc.objectName ?: "";
		var queryString = [];

		if ( !isEmptyString( args.multiActionUrl ?: "" ) ) {
			args.multiActionUrl = ListAppend( args.multiActionUrl, "_object_name=#objectName#", "&" );
		}

		ArrayAppend( queryString, "_object_name=#objectName#" );

		return ArrayToList( queryString, "&" );
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		var objectName = rc._object_name ?: "";

		args.extraFilters = args.extraFilters ?: [];

		ArrayAppend( args.extraFilters, { filter="_status != 'publish'" } );

		if ( !isEmptyString( objectName ) ) {
			ArrayAppend( args.extraFilters, { filter={ _object_name=objectName } } );
		}
	}

	private void function addRecordAction( event, rc, prc ) {
		// Pretend original object action.
		arguments.object = prc.record._object_name ?: "";

		runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = arguments
		);
	}

	private string function getEditRecordFormName( event, rc, prc, args={} ) {
		// Load orignal object form.
		var objectName = prc.record._object_name ?: "";

		return dataManagerCustomizationService.runCustomization(
			  objectName     = objectName
			, action         = "getEditRecordFormName"
			, defaultHandler = "admin.DataManager._getEditRecordFormName"
			, args           = { objectName=objectName }
		);
	}

	private array function getEditRecordActionButtons( event, rc, prc, args={} ) {
		// Load original object buttons.
		var objectName = prc.record._object_name ?: "";

		return runEvent(
			  event          = "admin.DraftManager._getEditRecordActionButtons"
			, private        = true
			, prepostExempt  = true
			, eventArguments = arguments
		);
	}

	private string function preRenderEditRecordForm( event, rc, prc, args={} ) {
		return renderView( view="admin/draftManager/_alert", args={
			  objectName  = prc.objectName
			, objectTitle = prc.objectTitle
			, recordLink  = isEmptyString( args.record._record_id ?: "" ) ? "" : event.buildAdminLink( objectName=args.record._object_name, recordId=args.record._record_id, operation="viewRecord" )
			, alertAction = "edit"
		} );
	}

	private string function editRecordForm( event, rc, prc, args={} ) {
		// Load original object data.
		if ( !IsEmpty( args.record._data ?: "" ) ) {
			StructAppend( args.record, DeserializeJSON( args.record._data ), true );
		}

		return runEvent(
			  event          = "admin.DataManager._editRecordForm"
			, prepostExempt  = true
			, private        = true
			, eventArguments = arguments
		);
	}

	private void function editRecordAction( event, rc, prc ) {
		// Pretend original object action.
		arguments.object   = prc.record._object_name ?: "";
		arguments.recordId = prc.record._record_id   ?: "";

		event.setValue( name="id", value=arguments.recordId );

		arguments.checkExistingRecord = false;
		arguments.formName            = getEditRecordFormName( argumentCollection=arguments );

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = arguments
		);
	}

	private any function deleteRecordAction( event, rc, prc, batch=false, batchAll=false, batchSrcArgs={} ) {
		var objectName = rc._object_name ?: ( prc.record._object_name ?: "" );

		arguments.object = "draftmanager_draft";
		arguments.audit  = true;

		event.setValue( name="postActionUrl", value=event.buildAdminLink( objectName=objectName, operation="listing", queryString="tab=draft" ) );

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = arguments
		);
	}

	private function getWorkflowForRecord( event, rc, prc, recordId="" ) {
		var objectName = prc.record._object_name ?: "";

		return draftManagerService.getWorkflowId( objectName=objectName );
	}

}