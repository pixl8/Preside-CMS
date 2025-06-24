component {
	property name="taskManagerService" inject="taskManagerService";
	private void function runCheck( required systemAlertCheck check ) {
		var overruns = taskManagerService.getTaskOverruns();

		if ( ArrayLen( overruns ) ) {
			check.fail();
		}
	}

	private string function render( event, rc, prc, args={} ) {
		args.overruns = taskManagerService.getTaskOverruns();
		return renderView( view="/admin/systemAlerts/taskManagerOverruns/render", args=args );
	}


// CONFIG SETTINGS
	private boolean function runAtStartup() {
		return true;
	}

	private string function schedule() {
		return "0 */5 * * * *"; // every five minutes
	}

	private string function defaultLevel() {
		return "warning";
	}

}