component {
	property name="adHocTaskManagerService" inject="adHocTaskManagerService";

	public void function runAdHocTask( event, rc, prc ) {
		adHocTaskManagerService.runTaskInThread( rc.taskId ?: "" );
		event.renderData( data={ ok=true }, type="json" );
	}
}