/**
 * @feature        cfflow
 * @presideService true
 * @singleton      true
 */
component implements="preside.system.modules.cfflow.models.implementation.interfaces.IWorkflowScheduler" {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public void function scheduleAutoActions(
		  required string workflowId
		, required struct instanceArgs
		, required string stepId
		, required array  timers
	){
		var sched = _calculateSchedule( arguments.timers );

		$createTask(
			  event             = "cfFlowHelpers.runScheduledAutoActions"
			, args              = { workflowId=arguments.workflowId, stepId=arguments.stepId, instanceArgs=arguments.instanceArgs }
			, runNow            = false
			, runIn             = sched.runIn
			, retryInterval     = sched.retries
			, discardOnComplete = true
		);
	}

	public void function unScheduleAutoActions(
		  required string workflowId
		, required struct instanceArgs
		, required string stepId
	){
		// not yet implemented
	}

// PRIVATE HELPERS
	private struct function _calculateSchedule( required array timers ) {
		var sched = {
			  runIn = CreateTimeSpan( 0, 0, 0, arguments.timers[ 1 ].getInterval() )
			, retries = []
		};

		var start = ( arguments.timers[ 1 ].getCount() == 1 ) ? 2 : 1;
		for( var i=start; i<=ArrayLen( arguments.timers ); i++ ) {
			var retry = {
				  tries    = arguments.timers[ i ].getCount()
				, interval = arguments.timers[ i ].getInterval()
			};
			if ( i==1 ) {
				retry.tries--;
			}

			ArrayAppend( sched.retries, retry );
		}

		return sched;
	}
}