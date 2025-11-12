/**
 * @feature        datamanagerWorkflow
 * @presideService true
 * @singleton      true
 */
component extends="CfFlowPresideStorage" {

	property name="dataManagerCustomizationService" inject="dataManagerCustomizationService";

	public struct function getState( required string workflowId, required struct instanceArgs ) {
		var args = _getObjectNameAndRecordId( argumentCollection=arguments );

		args.state = $getPresideObject( args.objectName ).selectData( id=args.recordId, returntype="struct" );

		dataManagerCustomizationService.runCustomization(
			  objectName = args.objectName
			, action     = "onWorkflowGetState"
			, args       = args
		);

		return args.state ?: {};
	}

	public void function appendState( required string workflowId, required struct instanceArgs, required struct state ){
		var args = _getObjectNameAndRecordId( argumentCollection=arguments );

		args.state = arguments.state;

		dataManagerCustomizationService.runCustomization(
			  objectName = args.objectName
			, action     = "preWorkflowAppendState"
			, args       = args
		);

		$getPresideObject( args.objectName ).updateData(
			  id                      = args.recordId
			, data                    = arguments.state
			, updateManyToManyRecords = true
		);

		dataManagerCustomizationService.runCustomization(
			  objectName = args.objectName
			, action     = "postWorkflowAppendState"
			, args       = args
		);
	}

	public void function setState( required string workflowId, required struct instanceArgs, required struct state ){
		appendState( argumentCollection=arguments );
	}


// PRIVATE HELPERS
	private struct function _getObjectNameAndRecordId( workflowId, instanceArgs ) {
		var instance = _getInstance( argumentCollection=arguments );

		return {
			  objectName = instance.reference
			, recordId   = instance.sub_reference
		};
	}

}