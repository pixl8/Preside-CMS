/**
 * @feature webflow
 */
component extends="preside.system.base.EnhancedDataManagerBase" {

	property name="webflowConfigurationService" inject="webflowConfigurationService";
	property name="webflowPlantUmlUtil"         inject="webflowPlantUmlUtil";
	property name="formsService"                inject="formsService";
	property name="flowDao"                     inject="preside:object:webflow_configuration";
	property name="stepDao"                     inject="preside:object:webflow_configuration_step";

	variables.permissionBase    = "webflows";
	variables.infoDescription   = "description";
	variables.sidebarNavigation = true;
	variables.tabs              = [ "activeInstances", "archivedInstances", "steps" ];

	public void function preHandler( event, action, eventArguments ) {
		super.preHandler( argumentCollection=arguments );

		event.setValue( name="pageFullWidth", value=true, private=true );
	}

// PUBLIC HANDLERS
	function flowsvg() {
		var webflowId = rc.webflowId ?: "";
		var collapse  = IsTrue( rc.collapse ?: true );

		content reset=true type="image/svg+xml";
		echo( webflowPlantUmlUtil.webflowToSvgDiagram( webflowId, collapse ) );
		abort;
	}

// PRIVATE HELPERs
	private void function _checkInstanceSingletonRedirect( event, rc, prc, args={} ) {
		var activeTab     = rc.tab ?: "activeInstances";
		var instObjName   = Trim( args.instanceObjectName ?: "" );
		var webflowId     = Trim( prc.record.webflow_id   ?: "" );
		var webflowRef    = Trim( prc.record.instance_ref ?: "" );
		var webflowConfig = webflowConfigurationService.getFlowConfig( webflowId=webflowId, instanceRef=webflowRef );
		var isSingleton   = isTrue( webflowConfig.is_singleton ?: "" );

		if ( Len( instObjName ) && isSingleton ) {
			//
		}
	}

// BETTER VIEW RECORD CUSTOMIZATIONS
	private string function _activeInstancesTab( event, rc, prc, args={} ) {
		args.instanceObjectName = "cfflow_workflow_instance";
		args.gridFields         = args.gridFields ?: [ "owner", "sub_reference", "datecreated" ];

		_checkInstanceSingletonRedirect( argumentCollection=arguments );

		return renderView( view="/admin/datamanager/webflow_configuration/_instancesTab", args=args )
	}

	private string function _archivedInstancesTab( event, rc, prc, args={} ) {
		args.instanceObjectName = "cfflow_workflow_archived_instance";
		args.gridFields         = args.gridFields ?: [ "owner", "sub_reference", "archive_reason", "time_taken", "date_started", "date_archived" ];

		_checkInstanceSingletonRedirect( argumentCollection=arguments );

		return renderView( view="/admin/datamanager/webflow_configuration/_instancesTab", args=args )
	}

	private string function _stepsTab( event, rc, prc, args={} ) {
		args.svgLink = event.buildAdminLink( linkto='datamanager.webflow_configuration.flowsvg', queryString='webflowId=#prc.record.webflow_id#' );
		args.fullSvgLink = event.buildAdminLink( linkto='datamanager.webflow_configuration.flowsvg', queryString='webflowId=#prc.record.webflow_id#&collapse=false' );
		args.stepstable = objectDataTable( objectName="webflow_configuration_step", args={
			  allowSearch     = false
			, allowFilter     = false
			, useMultiActions = false
			, compact         = true
		} );

		return renderView( view="/admin/datamanager/webflow_configuration/_stepsTab", args=args )
	}

// DATAMANAGER CUSTOMIZATIONS
	private string function listingViewlet( event, rc, prc, args={} ) {
		var webflowConfigCount = flowDao.selectData( recordCountOnly=true, savedFilters=[ "webflowsNonAdminFlows" ] );
		var globalStepCount    = stepDao.selectData( recordCountOnly=true, filter={ webflow="" } );

		event.include( "/css/admin/specific/viewtabs/" );

		args.tabs = [ {
			  id        = "flows"
			, iconClass = translateResource( "preside-objects.webflow_configuration:iconClass" ) & " blue"
			, title     = translateResource( "preside-objects.webflow_configuration:title" ) & " <span class=""badge"">#NumberFormat( webflowConfigCount )#</span>"
			, content   = renderViewlet( event="admin.datamanager._objectListingViewlet", args={ objectName="webflow_configuration" } )
		} ];

		if ( globalStepCount ) {
			args.tabs.append({
				  id        = "steps"
				, iconClass = translateResource( "preside-objects.webflow_configuration_step:iconClass" ) & " orange"
				, title     = translateResource( "preside-objects.webflow_configuration:viewtab.globalsteps.title" ) & " <span class=""badge"">#NumberFormat( globalStepCount )#</span>"
				, content   = objectDataTable( objectName="webflow_configuration_step", args={ gridFields=[ "step_id", "title", "short_title", "intro", "datemodified" ], multiActions=false } )
			} );
		}

		return renderView( view="/admin/datamanager/_tabs", args=args );
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		args.savedFilters = args.savedFilters ?: [];
		ArrayAppend( args.savedFilters, "webflowsNonAdminFlows" );
	}

	private string function getEditRecordFormName( event, rc, prc, args={} ) {
		var flowId            = prc.record.webflow_id ?: "";
		var mainForm          = "preside-objects.webflow_configuration";
		var subflowConfigForm = webflowConfigurationService.getSubflowConfigForms( flowId );
		var configForm        = webflowConfigurationService.getFlowConfigForm( flowId );

		for ( var subflowForm in subflowConfigForm ) {
			mainForm = formsService.getMergedFormName( mainForm, subflowForm );
		}

		if ( Len( Trim( configForm ) ) ) {
			return formsService.getMergedFormName( mainForm, configForm );
		}

		return mainForm;
	}

	private string function preRenderEditRecordForm( event, rc, prc, args={} ) {
		try {
			StructAppend( prc.record, DeSerializeJson( prc.record.config ), false );
		} catch( any e ) {}
	}

	private void function preEditRecordAction( event, rc, prc, args={} ) {
		var flowId            = prc.record.webflow_id ?: "";
		var subflowConfigForm = webflowConfigurationService.getSubflowConfigForms( flowId );
		var configForm        = webflowConfigurationService.getFlowConfigForm( flowId );
		var configStruct      = {};

		for ( var subflowForm in subflowConfigForm ) {
			configStruct.append( event.getCollectionForForm( subflowForm ) );
		}

		if ( Len( Trim( configForm ) ) ) {
			args.formData = args.formData ?: {};
			configStruct.append( event.getCollectionForForm( configForm ) );
		}

		args.formData.config = serializeJSON( configStruct );
	}
}