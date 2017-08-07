component {
	property name="taskmanagerService" inject="taskmanagerService";

	public void function runTasks( event, rc, prc ) {
		var result = taskmanagerService.runScheduledTasks();

		event.cachePage( false );

		event.renderData( data=result, type="json" );
	}
}