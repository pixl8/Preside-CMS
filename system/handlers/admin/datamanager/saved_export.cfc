/**
 * @feature admin and dataExport
 */
component {
	property name="presideObjectService"      inject="presideObjectService";
	property name="scheduledExportService"    inject="scheduledExportService";
	property name="customizationService"      inject="dataManagerCustomizationService";
	property name="datamanagerService"        inject="datamanagerService";
	property name="messageBox"                inject="messagebox@cbmessagebox";
	property name="cronUtil"                  inject="cronUtil";
	property name="i18n"                      inject="i18n";
	property name="dataExportTemplateService" inject="dataExportTemplateService";
	property name="formsService"              inject="FormsService";

	private boolean function checkPermission( event, rc, prc, args={} ) {
		var objectName       = "saved_export";
		var allowedOps       = datamanagerService.getAllowedOperationsForObject( objectName );
		var permissionsBase  = "savedExport"
		var alwaysDisallowed = [ "manageContextPerms" ];
		var operationMapped  = [ "read", "add", "edit", "delete", "batchdelete", "clone" ];
		var permissionKey    = "#permissionsBase#.#( args.key ?: "" )#";
		var hasPermission    = !alwaysDisallowed.find( args.key )
		                    && ( !operationMapped.find( args.key ) || allowedOps.find( args.key ) )
		                    && hasCmsPermission( permissionKey );

		if ( !hasPermission && IsTrue( args.throwOnError ?: "" ) ) {
			event.adminAccessDenied();
		}

		return hasPermission;
	}

	private void function postFetchRecordsForGridListing( event, rc, prc, args={} ) {
		var records = args.records ?: QueryNew('');

		for ( var record in records ) {
			querySetCell( records, "label", _decorateLabelForListing( record.id ), queryCurrentRow( records ) );
			querySetCell( records, "schedule", cronUtil.describeCronTabExression( record.schedule, i18n.getFwLanguageCode() ), queryCurrentRow( records ) );
		}
	}

	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var record     = args.record     ?: {};
		var recordId   = record.id       ?: "";

		args.actions = args.actions ?: [];

		args.actions.append( {
			  link       = event.buildAdminLink( objectName=objectName, operation="savedExportDownload", recordId=recordId )
			, icon       = "fa-download"
			, contextKey = "d"
		} );
	}

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		var objectName = rc.object_name ?: "";

		return "object_name=#objectName#";
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		var objectName= rc.object_name ?: "";

		if ( !isEmpty( objectName ) ) {
			args.extraFilters = args.extraFilters ?: [];

			args.extraFilters.append( { filter={ object_name=objectName } } );
		}
	}

	private void function postAddRecordAction( event, rc, prc, args={} ) {
		var newId = args.newId ?: "";

		if ( !isEmpty( newId ) ) {
			scheduledExportService.updateScheduleExport( newId );
		}
	}

	private void function preEditRecordAction( event, rc, prc, args={} ){
		if ( !isInstanceOf( args.validationResult ?: "", "ValidationResult" ) ) {
			return;
		}

		var formData = args.formData ?: {};

		if ( len( formData.schedule ?: "" ) && formData.schedule != "disabled" ) {
			var scheduleValidationMessage = cronUtil.validateExpression( formData.schedule );

			if ( len( trim( scheduleValidationMessage ) ) ) {
				args.validationResult.addError( fieldName="schedule", message=scheduleValidationMessage );
			}
		}

		var template = prc.record.template ?: "";
		var objectName = prc.record.object_name ?: "";

		formData.template_config = SerializeJson( dataExportTemplateService.getSubmittedConfig(
			  templateId = template
			, objectName = objectName
		) );
	}

	private void function postEditRecordAction( event, rc, prc, args={} ) {
		var recordId = rc.id ?: "";

		if ( !isEmpty( recordId ) ) {
			scheduledExportService.updateScheduleExport( recordId );
		}
	}

	private string function renderRecord( event, rc, prc, args={} ) {
		var detail       = prc.record ?: QueryNew('');
		args.objI18nBase = getResourceBundleUriRoot( args.objectName );

		for ( var d in detail ) {
			args.record = d;
		}

		if ( !isEmpty( args.record.object_name ?: "" ) ) {
			var i18nBase = getResourceBundleUriRoot( args.record.object_name );

			prc.pageTitle    = !isEmpty( args.record.label ?: "" ) ? args.record.label : prc.pageTitle;
			prc.pageSubTitle = translateResource(
				  uri          = i18nBase & "title.singular"
				, defaultValue = translateResource( uri="cms:savedexport.singular", defaultValue="" )
			) & " export";
		}

		if ( !isEmpty( args.record.schedule ?: "" ) && ( args.record.schedule neq "disabled" ) ) {
			args.exportSchedule = {
				  raw      = args.record.schedule
				, readable = cronUtil.describeCronTabExression( args.record.schedule, i18n.getFwLanguageCode() )
			};

			if ( !isEmptyString( args.exportSchedule.readable ?: "" ) ) {
				args.exportSchedule.readable = lCase( left( args.exportSchedule.readable, 1 ) ) & right( args.exportSchedule.readable, len( args.exportSchedule.readable )-1 );
			}
		}

		args.hasHistory = booleanFormat( scheduledExportService.getSavedExportHistory( args.record.id ).recordcount ?: 0 );

		event.includeData( data={ defaultPageLength=5 } );

		return renderView( view="/admin/savedExport/_recordView", args=args );
	}

	private void function extraTopRightButtonsForViewRecord( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var recordId   = prc.recordId    ?: "";
		args.actions   = args.actions    ?: [];

		args.actions.prepend({
			  link      = event.buildAdminLink( linkto="datamanager.saved_export.adhocRunSavedExport", queryString="savedExportId=#recordId#" )
			, btnClass  = "btn-info"
			, iconClass = "fa-redo-alt"
			, title     = translateResource( "preside-objects.saved_export:runExport.btn" )
		} );
	}

	public void function adhocRunSavedExport( event, rc, prc, args={} ) {
		var recordId = rc.savedExportId ?: "";

		if ( !isEmptyString( recordId ) ) {
			scheduledExportService.runExport( recordId );

			messageBox.info( translateResource( uri="cms:datamanager.runsavedexport.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( objectName="saved_export", operation="viewRecord", recordId=recordId ) );
		} else {
			messageBox.error( translateResource( uri="cms:datamanager.runsavedexport.error" ) );
			setNextEvent( url=event.buildAdminLink( objectName="saved_export" ) );
		}
	}

	private string function objectBreadcrumb() {
		var objectName = rc.object_name ?: "";

		if ( Len( Trim( objectName ) ) ) {
			customizationService.runCustomization(
				  objectName     = objectName
				, action         = "objectBreadcrumb"
				, defaultHandler = "admin.datamanager._objectBreadcrumb"
				, args           = { objectName=objectName, objectTitle=translateResource( "preside-objects.#objectName#:title" ) }
			);
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="preside-objects.saved_export:title" )
			, link  = event.buildAdminLink( objectName="saved_export" )
		);
	}

	private string function getEditRecordFormName( event, rc, prc, args={} ) {
		var formName = dataExportTemplateService.getSaveExportFormName(
			  templateId = prc.record.template    ?: ""
			, objectName = prc.record.object_name ?: ""
			, baseForm   = "preside-objects.saved_export.admin.edit"
		);

		if ( Len( prc.record.filter ?: "" ) ) {
			formName = formsService.getMergedFormName(
				  formName          = formName
				, mergeWithFormName = "preside-objects.saved_export.admin.edit.with.filter"
			);
		}

		return formName;
	}

	private void function preRenderEditRecordForm( event, rc, prc, args={} ) {
		rc.filterObject = args.record.object_name ?: "";

		if ( IsJson( args.record.template_config ?: "" ) ) {
			var templateConfig = DeserializeJson( args.record.template_config );
			if ( IsStruct( templateConfig ) ) {
				StructAppend( args.record, templateConfig, false );
			}
		}

		args.additionalArgs                 = args.additionalArgs                 ?: {};
		args.additionalArgs.fields          = args.additionalArgs.fields          ?: {};
		args.additionalArgs.fields.exporter = args.additionalArgs.fields.exporter ?: {};

		args.additionalArgs.fields.exporter.allowedExporters = dataExportTemplateService.getAllowedExporters(
			  templateId = ( args.record.template ?: "" )
			, objectName = rc.filterObject
		);
	}

// HELPERS
	private string function _decorateLabelForListing( required string recordId ) {
		var detail     = presideObjectService.selectData( objectName="saved_export", id=arguments.recordId );
		var objectName = detail.object_name ?: "";
		var baseUri    = "";

		args.icon        = "";
		args.label       = detail.label       ?: "";
		args.description = detail.description ?: "";

		if ( !isEmpty( objectName ) ) {
			baseUri   = presideObjectService.getResourceBundleUriRoot( objectName );
			args.icon = translateResource( uri=baseUri & "iconclass", defaultValue="fa-database" );
		}

		return renderView( view="/admin/savedExport/_savedExportLabel", args=args );
	}
}