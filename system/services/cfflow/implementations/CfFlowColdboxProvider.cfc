/**
 * @feature        cfflow
 * @presideService true
 * @singleton      true
 */
component implements="preside.system.modules.cfflow.models.implementation.interfaces.IWorkflowCondition,preside.system.modules.cfflow.models.implementation.interfaces.IWorkflowFunction" {

	public any function init() {
		return;
	}

	public void function do( required WorkflowInstance wfInstance, required struct args ){
		var handler     = arguments.args.event ?: "";
		var handlerArgs = StructCopy( arguments.args.args ?: {} );


		if ( $getColdbox().handlerExists( handler ) ) {
			$runEvent(
				  event          = handler
				, private        = true
				, prePostExempt  = true
				, eventArguments = { args=handlerArgs, wfInstance=arguments.wfInstance }
			);
		} else {
			throw( "The handler, [#handler#], does not exist.", "preside.workflow.handler.not.exists" );
		}
	}

	public boolean function evaluate( required WorkflowInstance wfInstance, required struct args ){
		var handler     = arguments.args.event ?: "";
		var handlerArgs = StructCopy( arguments.args.args ?: {} );
		var result      = false;

		if ( $getColdbox().handlerExists( handler ) ) {
			result = $runEvent(
				  event          = handler
				, private        = true
				, prePostExempt  = true
				, eventArguments = { args=handlerArgs, wfInstance=arguments.wfInstance }
			);
		} else {
			throw( "The handler, [#handler#], does not exist.", "preside.workflow.handler.not.exists" );
		}

		return IsBoolean( local.result ?: "" ) && result;
	}

}