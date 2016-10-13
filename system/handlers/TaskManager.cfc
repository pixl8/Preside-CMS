component {
	property name="taskmanagerService" inject="taskmanagerService";

	public void function runTasks( event, rc, prc ) {
		var result = taskmanagerService.runScheduledTasks();

		event.renderData( data=result, type="json" );
	}
}