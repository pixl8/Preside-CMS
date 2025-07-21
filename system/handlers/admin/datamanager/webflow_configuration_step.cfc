/**
 * @feature webflow
 */
component extends="preside.system.base.EnhancedDataManagerBase" {

	property name="webflowConfigurationService" inject="webflowConfigurationService";
	property name="webflowSpecLibrary"          inject="webflowSpecLibrary";
	property name="formsService"                inject="formsService";
	property name="flowConfigDao"               inject="presidecms:object:webflow_configuration";

	variables.permissionBase = "webflows"
	variables.infoCol1 = variables.infoCol1 ?: [];
	variables.infoCol2 = variables.infoCol2 ?: [];
	variables.infoCol3 = variables.infoCol3 ?: [];


// DATAMANAGER CUSTOMIZATIONS
	public void function viewRecord() {
		setNextEvent( url=event.buildAdminLink( objectName="webflow_configuration_step", operation="editRecord", recordId=( rc.id ?: "" ) ) );
	}

	private string function objectBreadcrumb() {
		var webflowId = prc.record.webflow ?: ( rc.webflow ?: "" );

		var args = {
			  objectName  = "webflow_configuration"
			, objectTitle = translateResource( "preside-objects.webflow_configuration:title" )
			, recordId    = webflowId
			, recordLabel = renderLabel( "webflow_configuration", webflowId )
		};

		customizationService.runCustomization(
			  objectName     = "webflow_configuration"
			, action         = "objectBreadcrumb"
			, defaultHandler = "admin.datamanager._objectBreadcrumb"
			, args           = args
		);

		if ( Len( Trim( webflowId ) ) ) {
			customizationService.runCustomization(
				  objectName     = "webflow_configuration"
				, action         = "recordBreadcrumb"
				, defaultHandler = "admin.datamanager._recordBreadcrumb"
				, args           = args
			);
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "preside-objects.webflow_configuration:field.steps.title" )
			, link  = event.buildAdminLink( objectName="webflow_configuration", recordId=webflowId, queryString="tab=steps" )
		);
	}

	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		args.actions = args.actions ?: [];
		for ( var i=ArrayLen( args.actions ); i>0; i-- ) {
			if ( ( args.actions[ i ].contextKey ?: "" ) != "e" ) {
				ArrayDeleteAt( args.actions, i );
			}
		}
	}

	private string function buildListingLink() {
		var webflowId = prc.record.webflow ?: ( rc.webflow ?: "" );

		if ( Len( Trim( webflowId ) ) ) {
			return event.buildAdminLink( objectName="webflow_configuration", recordId=webflowId );
		}

		return event.buildAdminLink( objectName="webflow_configuration", queryString="tab=steps" );
	}

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		if ( ( prc.objectName ?: "" ) == "webflow_configuration" && Len( Trim( prc.recordId ?: "" ) ) ) {
			return "webflow=#prc.recordId#";
		}
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		var webflowId = rc.webflow ?: "";

		args.extraFilters = args.extraFilters ?: [];
		args.extraFilters.append( { filter={ webflow=webflowId } } );
	}

	private string function getEditRecordFormName( event, rc, prc, args={} ) {
		var flow       = flowConfigDao.selectData( id=prc.record.webflow ?: "", selectFields=[ "webflow_id" ] );
		var stepId     = prc.record.step_id ?: "";
		var position   = prc.record.position_type ?: "";
		var configForm = webflowConfigurationService.getStepConfigForm( flow.webflow_id, stepId );
		var finalFormName = "preside-objects.webflow_configuration_step";
		var canCancel     = false;

		if ( Len( flow.webflow_id ?: "" ) ) {
			canCancel = webflowSpecLibrary.getWebflowStep( flow.webflow_id, stepId ).getCanCancel();
		}

		if ( Len( Trim( configForm ) ) ) {
			finalFormName = formsService.getMergedFormName( finalFormName, configForm );
		}

		if ( position == "end" ) {
			finalFormName = formsService.createForm( basedOn=finalFormName, generator=function( formDefinition ){
				formDefinition.deleteFieldset(
					  id  = "navigation"
					, tab = "default"
				);
			} );
		} else if ( position == "start" ) {
			finalFormName = formsService.createForm( basedOn=finalFormName, generator=function( formDefinition ){
				formDefinition.deleteField(
					  name      = "back_button"
					, tab       = "default"
					, fieldset  = "navigation"
				);
			} );
		}

		if ( position == "end" || !canCancel ) {
			finalFormName = formsService.createForm( basedOn=finalFormName, generator=function( formDefinition ){
				formDefinition.deleteField(
					  name      = "cancel_button"
					, tab       = "default"
					, fieldset  = "navigation"
				);
			} );
		}

		return finalFormName;
	}

	private string function preRenderEditRecordForm( event, rc, prc, args={} ) {
		try {
			StructAppend( prc.record, DeSerializeJson( prc.record.config ), false );
		} catch( any e ) {}
	}

	private void function preEditRecordAction( event, rc, prc, args={} ) {
		var stepId    = prc.record.step_id ?: "";
		var webflowId = prc.record.webflow ?: "";

		if ( Len( Trim( webflowId ) ) ) {
			webflowId = flowConfigDao.selectData( id=webflowId, selectFields=[ "webflow_id" ] ).webflow_id;
		}

		var configForm = webflowConfigurationService.getStepConfigForm(
			  stepId    = stepId
			, webflowId = webflowId
		);

		if ( Len( Trim( configForm ) ) ) {
			args.formData = args.formData ?: {};
			args.formData.config = SerializeJson( event.getCollectionForForm( configForm ) );
		}
	}

}