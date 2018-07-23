component {

	property name="presideTaskmanagerHeartBeat" inject="presideTaskmanagerHeartBeat";
	property name="presideAdhocTaskHeartBeat"   inject="presideAdhocTaskHeartBeat";
	property name="taskManagerService"          inject="taskManagerService";
	property name="adhocTaskManagerService"     inject="adhocTaskManagerService";

	public void function startTaskManagerHeartbeat( event, rc, prc ) {
		presideTaskmanagerHeartBeat.start();
		event.renderData( data={ ok=true }, type="json" );
	}

	public void function startAdhocTaskManagerHeartbeat( event, rc, prc ) {
		presideAdhocTaskHeartBeat.start();
		event.renderData( data={ ok=true }, type="json" );
	}

	public void function scheduledTask( event, rc, prc ) {
		var taskKey = rc.taskKey ?: "";
		var args    = rc.args    ?: "";

		if ( Len( Trim( args ) ) ) {
			try {
				args = DeserializeJson( args );
			} catch( any e ) {
				logError( e );
				args = {};
			}
		} else {
			args = {};
		}

		taskManagerService.runTask(
			  taskKey = taskKey
			, args    = args
		);

		event.renderData( data={ ok=true }, type="json" );
	}

	public void function adhocTask( event, rc, prc ) {
		var taskId = rc.taskId ?: "";

		adhocTaskManagerService.runTaskInThread( taskId=taskId );
		event.renderData( data={ ok=true }, type="json" );
	}

}