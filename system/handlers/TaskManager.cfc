component {
	property name="taskmanagerService"      inject="taskmanagerService";
	property name="adHocTaskManagerService" inject="adHocTaskManagerService";

	public void function runTasks( event, rc, prc ) {
		var result = taskmanagerService.runScheduledTasks();

		event.cachePage( false );

		event.renderData( data=result, type="json" );
	}

	public void function runAdHocTask( event, rc, prc ) {
		adHocTaskManagerService.runTaskInThread( rc.taskId ?: "" );
		event.renderData( data={ ok=true }, type="json" );
	}
}