component {

	property name="cfflow" inject="cfflow@cfflow";

	private boolean function runScheduledAutoActions( event, rc, prc, args={}, logger, progress ) {
		var wfId   = args.workflowId   ?: "";
		var iArgs  = args.instanceArgs ?: {};
		var stepId = args.stepId       ?: "";

		if ( !cfflow.instanceExists( workflowId=wfId, instanceArgs=iArgs ) ) {
			// ensure that the adhoc task is  completed and removed
			return true;
		}

		try {
			// if no actions are executed, we will return false
			// and this task will be rescheduled if need be
			return cfflow.doAutoActions(
				  workflowId   = wfId
				, instanceArgs = iArgs
				, stepId       = stepId
			);

		} catch( "cfflow.step.not.active" e ) {
			// if the step is no longer active,
			// we should complete this task
			return true;
		}
	}
}