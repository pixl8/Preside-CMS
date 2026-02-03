/**
 * @feature admin and dataExport
 */
component extends="preside.system.base.adminHandler" {
	property name="presideObjectService"      inject="presideObjectService";
	property name="loginService"              inject="loginService";
	property name="dataExportTemplateService" inject="dataExportTemplateService";

	public void function prehandler( event, rc, prc, args={} ) {
		super.preHandler( argumentCollection=arguments );

		if ( !isEmpty( rc.object ?: "" ) ) {
			var i18nBase = presideObjectService.getResourceBundleUriRoot( rc.object );

			event.addAdminBreadCrumb(
				  title = translateResource( uri=i18nBase & "title.singular" )
				, link  = event.buildAdminLink( objectName=rc.object )
			);
		} else {
			event.notFound();
		}
	}

	public void function saveExport( event, rc, prc, args={} ) {
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:savedexport.saveexport.title" )
			, link  = event.buildAdminLink( linkto="dataExport.saveExport", persistStruct=rc )
		);

		prc.pageIcon  = "save";
		prc.pageTitle = translateResource( uri="cms:savedexport.saveexport.title" );

		rc.fields = rc.exportFields ?: ""; // backward compat fix

		if ( !isEmpty( rc.object ?: "" ) ) {
			var i18nBase = presideObjectService.getResourceBundleUriRoot( rc.object );
			prc.pageSubtitle = translateResource( uri="cms:savedexport.saveexport.subtitle",  data=[ translateResource( uri=i18nBase & "title.singular", defaultValue="" ) ] );

			if ( !Len( Trim( rc.filename ?: "" ) ) ) {
				rc.filename = slugify( translateResource( uri=i18nBase & "title", defaultValue="" ) );
			}

			rc.filterObject = rc.object;
			prc.saveExportForm = dataExportTemplateService.renderSaveExportForm(
				  templateId = rc.exportTemplate ?: ""
				, objectName = rc.object
				, hasFilter  = Len( rc.filterExpressions ?: "" )
			);
		}

	}

	public void function saveExportAction( event, rc, prc, args={} ) {
		var formData         = event.getCollectionForForm();
		var validationResult = validateForms();

		if ( !validationResult.validated() ) {
			messageBox.error( translateResource( uri="cms:datamanager.saveexport.error" ) );
			setNextEvent( url=event.buildAdminLink( linkto="dataExport.saveExport" ), persistStruct=formData );
		}

		var newSavedExportId = "";
		var data             =  {
			  label              = formData.label              ?: ""
			, template           = formData.exportTemplate     ?: ""
			, description        = formData.description        ?: ""
			, file_name          = formData.filename           ?: ""
			, object_name        = formData.object             ?: ""
			, filter_string      = formData.exportFilterString ?: ""
			, fields             = formData.fields             ?: ""
			, exporter           = formData.exporter           ?: ""
			, order_by           = formData.orderBy            ?: ""
			, search_query       = formData.searchQuery        ?: ""
			, created_by         = loginService.getLoggedInUserId()
			, recipients         = formData.recipients         ?: ""
			, omit_empty_exports = formData.omit_empty_exports ?: 0
			, schedule           = formData.schedule           ?: "disabled"
			, template_config    = SerializeJson( dataExportTemplateService.getSubmittedConfig( templateId=( formData.exportTemplate ?: "" ), objectName=( formData.object ?: "" ) ) )
		};

		if ( isFeatureEnabled( "rulesEngine" ) ) {
			data.filter       = formData.filterExpressions ?: "";
			data.saved_filter = formData.savedFilters      ?: "";
		}


		try {
			newSavedExportId = presideObjectService.insertData(
				  objectName              = "saved_export"
				, data                    = data
				, insertManyToManyRecords = true
			);
		} catch ( any e ) {
			logError( e );
		}

		if( !isEmpty( newSavedExportId ) ) {
			messageBox.info( translateResource( uri="cms:datamanager.saveexport.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( objectName="saved_export", operation="listing", queryString="object_name=#formData.object#" ) );
		} else {
			messageBox.error( translateResource( uri="cms:datamanager.saveexport.error" ) );
			setNextEvent( url=event.buildAdminLink( objectName=formData.object, operation="listing" ) );
		}
	}
}