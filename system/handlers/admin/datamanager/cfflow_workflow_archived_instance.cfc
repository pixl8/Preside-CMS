/**
 * @feature    cfflow
 */
component extends="preside.system.base.EnhancedDataManagerBase" {
	variables.permissionBase = "webflows";
	variables.infoCardStyle  = "definitionList";
	variables.infoCol1       = [ "archive_reason" ];
	variables.infoCol2       = [ "time_taken" ];
	variables.infoCol3       = [ "date_archived" ];

	property name="webflowConfigService" inject="webflowConfigurationService";

	private string function _defaultTab( event, rc, prc, args={} ) {
		args.savedState = Trim( args.record.state ?: "" );
		args.savedState = IsJSON( args.savedState ) ? DeserializeJSON( args.savedState ) : {};

		return renderView( view="/admin/datamanager/webflow_configuration/_instanceDetail", args=args )
	}

// DATAMANAGER CUSTOMISATIONs
	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		var objectName = Trim( prc.objectName         ?: "" );
		var webflowId  = Trim( prc.record?.webflow_id ?: "" );

		if ( objectName == "webflow_configuration" ) {
			return "webflow_id=#webflowId#";
		}

		return "";
	}
	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		args.extraFilters = args.extraFilters   ?: [];
		var webflowId     = Trim( rc.webflow_id ?: "" );

		if ( Len( webflowId ) ) {
			ArrayAppend( args.extraFilters, { filter={ reference=webflowId } } );
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
			}
		}
	}
}