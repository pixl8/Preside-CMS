/**
 * Potential TODO: move out of interceptors
 * and implement directly in core services
 * as a first class citizen
 */
component extends="coldbox.system.Interceptor" {

	property name="datamanagerWorkflowService"       inject="delayedInjector:datamanagerWorkflowService";
	property name="datamanagerWorkflowFilterService" inject="delayedInjector:datamanagerWorkflowFilterService";

	public void function configure() {}

	public void function postReadPresideObject( event, interceptData ) {
		if ( !isFeatureEnabled( "datamanagerworkflow" ) ) {
			return;
		}

		var meta                 = interceptData.objectMeta ?: {};
		var objectName           = ListLast( meta.name, "." );
		var isDmWorkflowEnabled  = isBoolean( meta.datamanagerWorkflowEnabled ?: "" ) && meta.datamanagerWorkflowEnabled;

		if ( isDmWorkflowEnabled ) {
			var properties = meta.properties    ?: {};
			var propNames  = meta.propertyNames ?: [];

			if ( !StructKeyExists( properties, "datamanager_workflow_status" ) ) {
				properties.datamanager_workflow_status = { type="string", formula="concat( '#objectName#.', ${prefix}id )", autofilter=false, renderer="datamanagerWorkflowStatus" };
				ArrayAppend( propNames, "datamanager_workflow_status" );
			}
		}
	}

	public void function postInsertObjectData( event, interceptData ) {
		if ( !isFeatureEnabled( "datamanagerworkflow" ) ) {
			return;
		}
		datamanagerWorkflowService.get().createWorkflowForNewRecord(
			  objectName = ( arguments.interceptData.objectName ?: "" )
			, recordId   = ( arguments.interceptData.newId      ?: "" )
		);
	}

	public void function preDeleteObjectData( event, interceptData ) {
		if ( !isFeatureEnabled( "datamanagerworkflow" ) ) {
			return;
		}
		datamanagerWorkflowService.get().deleteRelatedFlows( argumentCollection=arguments.interceptData );
	}
}