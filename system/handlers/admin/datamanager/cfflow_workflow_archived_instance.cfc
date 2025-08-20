/**
 * @feature    cfflow
 */
component extends="preside.system.base.EnhancedDataManagerBase" {
	variables.permissionBase = "webflows";
	variables.infoCardStyle  = "definitionList";
	variables.tabs           = [ "transitions", "default" ];
	variables.infoCol1       = [ "owner" ];
	variables.infoCol2       = [ "sub_reference", "time_taken" ];
	variables.infoCol3       = [ "date_archived", "archive_reason" ];

	property name="webflowConfigService"   inject="webflowConfigurationService";
	property name="webflowInstanceService" inject="WebflowInstanceService";
	property name="webflowLibrary"         inject="WebflowSpecLibrary";
	property name="webflowUtilsService"    inject="WebflowUtilsService";

	private string function _transitionsTab( event, rc, prc, args={} ) {
		args.diagramUrl = event.buildAdminLink(
			  linkto      = "datamanager.cfflow_workflow_instance.flowDiagram"
			, queryString = "objectName=#args.objectName#&recordId=#args.recordId#"
		);

		args.transitionQuery = webflowInstanceService.getArchiveInstanceTransitions( archiveInstanceId=args.recordId );
		args.instanceHistory = renderView( view="/admin/webflow/_instanceHistories", args=args );

		return renderView( view="/admin/webflow/_instanceTransitions", args=args );
	}

	private string function _defaultTab( event, rc, prc, args={} ) {
		args.savedState    = Trim( args.record.state ?: "" );
		args.savedState    = IsJSON( args.savedState ) ? DeserializeJSON( args.savedState ) : {};
		args.hasPermission = hasCmsPermission( "webflows.admin.viewSavedState" );
		args.printedState  = webflowUtilsService.prettyPrintSavedState( savedState=args.savedState );

		return renderView( view="/admin/datamanager/webflow_configuration/_instanceDetail", args=args )
	}

	private string function _infoCardDate_archived( event, rc, prc, args={} ) {
		var data = args.record.date_archived ?: "";

		if ( IsDate( data ) ) {
			return renderContent( "datetime", data, "relative" );
		}
		return "";
	}

// DATAMANAGER CUSTOMISATIONs
	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		var qs         = [];
		var objectName = Trim( prc.objectName         ?: "" );
		var webflowId  = Trim( prc.record?.webflow_id ?: "" );

		if ( objectName == "webflow_configuration" ) {
			ArrayAppend( qs, "webflow_id=#webflowId#" );
		}

		if ( Len( Trim( rc.reference ?: "" ) ) ) {
			ArrayAppend( qs, "reference=#reference#" );
		} else if ( Len( Trim( prc.record.instance_ref ?: "" ) ) ) {
			ArrayAppend( qs, "reference=#prc.record.instance_ref#" );
		}

		return ArrayToList( qs, "&" );
	}
	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		args.extraFilters = args.extraFilters   ?: [];
		var webflowId     = Trim( rc.webflow_id ?: "" );
		var referenceId   = Trim( rc.reference ?: "" );

		if ( Len( webflowId ) ) {
			ArrayAppend( args.extraFilters, { filter={ reference=webflowId } } );
		}
		if ( Len( referenceId ) ) {
			ArrayAppend( args.extraFilters, { filter={ sub_reference=referenceId } } );
		}
	}

	private void function objectBreadcrumb( event, rc, prc, args={} ) {
		event.addAdminBreadCrumb(
			  title = translateResource( uri="preside-objects.webflow_configuration:title" )
			, link  = event.buildAdminLink( objectName="webflow_configuration" )
		);

		if ( Len( Trim( prc.recordId ?: "" ) ) ) {
			var webflowId     = Trim( prc.record.reference     ?: "" );
			var webflowRef    = Trim( prc.record.sub_reference ?: "" );
			var webflow       = webflowLibrary.getWebflow( webflowId );
			var webflowConfig = webflowConfigService.getFlowConfig(
				  webflowId   = webflow.getId()
				, instanceRef = webflow.getSingleton() ? "" : webflowRef
			);

			if ( Len( webflowConfig.id ?: "" ) ) {
				event.addAdminBreadCrumb(
					  title = renderLabel( "webflow_configuration", webflowConfig.id )
					, link  = event.buildAdminLink( objectName="webflow_configuration", recordId=webflowConfig.id )
				);

				event.addAdminBreadCrumb(
					  title = translateResource( uri="preside-objects.webflow_configuration:viewtab.archivedInstances.title" )
					, link  = event.buildAdminLink( objectName="webflow_configuration", recordId=webflowConfig.id, queryString="tab=archivedInstances" )
				);

				if ( webflow.getSingleton() && Len( webflowRef ) ) {
					event.addAdminBreadCrumb(
						  title = renderContent( renderer="webflowInstanceReference", data=webflowRef, args={ webflowId=webflowId, plainText=true } )
						, link  = event.buildAdminLink( objectName="webflow_configuration", recordId=webflowConfig.id, queryString="tab=archivedInstances&reference=#webflowRef#" )
					);
				}
			}
		}
	}
}