component extends="preside.system.base.EnhancedDataManagerBase" {

	property name="presideObjectService"            inject="PresideObjectService";
	property name="dataManagerService"              inject="DataManagerService";
	property name="draftManagerService"             inject="DraftManagerService";
	property name="dataManagerCustomizationService" inject="DataManagerCustomizationService";
	property name="dataManagerWorkflowService"      inject="DataManagerWorkflowService";
	property name="adminDataViewsService"           inject="AdminDataViewsService";

	variables.permissionBase = "draftManager";
	variables.infoCol3       = [];
	variables.tabs           = [ "draft" ];

	private void function rootBreadcrumb( event, rc, prc, args={} ) {
		var objectName = prc.record._object_name ?: "";

		dataManagerCustomizationService.runCustomization(
			  objectName     = objectName
			, action         = "rootBreadcrumb"
			, defaultHandler = "admin.DraftManager._rootBreadcrumb"
			, args           = args
		);
	}

	private void function objectBreadcrumb( event, rc, prc, args={} ) {
		var objectName = prc.record._object_name ?: "";

		dataManagerCustomizationService.runCustomization(
			  objectName     = objectName
			, action         = "objectBreadcrumb"
			, defaultHandler = "admin.DraftManager._objectBreadcrumb"
			, args           = args
		);
	}

	private void function recordBreadcrumb( event, rc, prc, args={} ) {
		var objectName = prc.record._object_name ?: "";

		dataManagerCustomizationService.runCustomization(
			  objectName     = objectName
			, action         = "recordBreadcrumb"
			, defaultHandler = "admin.DraftManager._recordBreadcrumb"
			, args           = args
		);
	}

	private string function _draftTab( event, rc, prc, args={} ) {
		args.objectName = prc.record._object_name ?: "";
		args.recordId   = prc.record._record_id   ?: "";

		if ( ( args.record._status ?: "" ) == "publish" ) {
			messageBox.info( translateResource(
				  uri  = "draftManager:message.published.description"
				, data = [
					  translateResource( uri="preside-objects.#args.objectName#:title.singular", defaultValue=args.objectName )
					, '<a href="#event.buildAdminLink( objectName=args.objectName, operation="viewRecord", recordId=args.recordId )#">#renderLabel( objectName=args.objectName, recordId=args.recordId )#</a>'
				  ]
			) );

			setNextEvent( url=event.buildAdminLink( objectName=args.objectName ) );
		}

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

			StructDelete( data, "id" );
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

	private array function getTopRightButtonsForViewRecord( event, rc, prc, args={} ) {
		var objectName  = "draftmanager_draft";
		var objectTitle = prc.objectTitle ?: "";
		var recordId    = prc.recordId    ?: "";
		var recordLabel = prc.recordLabel ?: "";
		var language    = rc.language     ?: "";
		var actions     = [];
		var children    = [];

		if ( IsTrue( prc.canView ?: "" ) ) {
			var sourceObjectName = args.record._object_name ?: "";

			var previewActions = customizationService.runCustomization(
				  objectName     = sourceObjectName
				, action         = "getDraftPreviewActionButtons"
				, defaultHandler = "admin.DraftManager._getDraftPreviewActionButtons"
				, args           = args
			);

			if ( !IsEmpty( previewActions ) ) {
				ArrayPrepend( actions, previewActions, true );
			}
		}

		if ( IsTrue( prc.canDelete ?: "" ) ) {
			if ( ArrayLen( children ) ) {
				ArrayAppend( children, "---" );
			}

			var record = args.record ?: ( prc.record ?: {} );
			if ( isQuery( record ) ) {
				record = QueryRowToStruct( record );
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
				, iconClass = translateResource( uri="draftManager:action.default.iconClass" )
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
		var draftId       = prc.record.id           ?: "";
		var objectURIRoot = presideObjectService.getResourceBundleUriRoot( objectName=objectName );

		if ( !isEmptyString( recordId ) ) {
			prc.recordLabel = renderLabel( objectName=objectName, recordId=recordId );
		}

		prc.pageTitle   = prc.recordLabel;
		prc.pageIcon    = translateResource( uri="#objectURIRoot#iconClass", defaultValue="fa-database" );

		return renderView( view="admin/draftManager/_alertDraft", args={
			  objectName = objectName
			, recordId   = recordId
			, draftId    = draftId
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
		var objectName = prc.record._object_name ?: "";
		var recordId   = prc.record._record_id   ?: "";
		var draftId    = prc.record.id           ?: "";

		return dataManagerCustomizationService.runCustomization(
			  objectName     = objectName
			, action         = "preRenderEditRecordForm"
			, defaultResult  = ""
			, args           = args
		)
		& renderView( view="admin/draftManager/_alertDraft", args={
			  objectName  = objectName
			, recordId    = recordId
			, draftId     = draftId
		} );
	}

	private string function editRecordForm( event, rc, prc, args={} ) {
		// Load original object data.
		if ( !IsEmpty( args.record._data ?: "" ) ) {
			var data = DeserializeJSON( args.record._data );

			StructDelete( data, "id" );
			StructAppend( args.record, data, true );
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

		if ( draftManagerService.isDraftAction() ) {
			runEvent(
				  event          = "admin.DataManager._editRecordAction"
				, prePostExempt  = true
				, private        = true
				, eventArguments = arguments
			);
		} else {
			runEvent(
				  event          = "admin.DraftManager._publishDraftRecordAction"
				, private        = true
				, prepostExempt  = true
				, eventArguments = arguments
			);
		}
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