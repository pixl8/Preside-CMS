component {

	property name="presideTaskmanagerHeartBeat" inject="presideTaskmanagerHeartBeat";
	property name="cacheboxReapHeartBeat"       inject="cacheboxReapHeartBeat";
	property name="presideAdhocTaskHeartBeat"   inject="presideAdhocTaskHeartBeat";
	property name="taskManagerService"          inject="taskManagerService";
	property name="healthcheckService"          inject="healthcheckService";
	property name="adhocTaskManagerService"     inject="adhocTaskManagerService";
	property name="emailQueueConcurrency"       inject="coldbox:setting:email.queueConcurrency";
	property name="assetQueueConcurrency"       inject="coldbox:setting:assetManager.queue.concurrency";

	public void function preHandler( event, action, eventArguments ) {
		event.setUseQueryCache( false );
	}

	public void function startTaskManagerHeartbeat( event, rc, prc ) {
		if ( isFeatureEnabled( "taskmanagerHeartBeat" ) ) {
			presideTaskmanagerHeartBeat.start();
			event.renderData( data={ ok=true }, type="json" );
		} else {
			event.renderData( data={ ok=false, message="Taskmanager heartbeat is not enabled on this application instance." }, type="json" );
		}
	}

	public void function startCacheReapHeartbeat( event, rc, prc ) {
		cacheboxReapHeartBeat.start();
		event.renderData( data={ ok=true }, type="json" );
	}

	public void function startAdhocTaskManagerHeartbeat( event, rc, prc ) {
		if ( isFeatureEnabled( "adhocTaskHeartBeat" ) ) {
			presideAdhocTaskHeartBeat.start();
			event.renderData( data={ ok=true }, type="json" );
		} else {
			event.renderData( data={ ok=false, message="Adhoc taskmanager heartbeat is not enabled on this application instance." }, type="json" );
		}
	}

	public void function startHealthCheckHeartbeat( event, rc, prc ) {
		if ( isFeatureEnabled( "healthchecks" ) ) {
			var serviceId = rc.serviceId ?: "";
			if( healthcheckService.serviceExists( serviceId=serviceId ) ) {
				getModel( "healthCheckHeartbeat#serviceId#" ).start();

				event.renderData( data={ ok=true }, type="json" );
			} else {
				event.renderData( data={ ok=false, message="Healthcheck service ID [#serviceId#] not found!" }, type="json" );
			}
		} else {
			event.renderData( data={ ok=false, message="Healthchecks are not enabled on this application instance." }, type="json" );
		}
	}

	public void function startEmailQueueHeartbeat( event, rc, prc ) {
		if ( isFeatureEnabled( "emailQueueHeartBeat" ) ) {
			var instanceNumber = Val( rc.instanceNumber ?: "" );

			if ( instanceNumber > 0 && instanceNumber <= emailQueueConcurrency ) {
				getModel( "PresideEmailQueueHeartBeat#instanceNumber#" ).start();
				event.renderData( data={ ok=true }, type="json" );
			} else {
				event.renderData( data={ ok=false, message="Queue heartbeat instance [#instanceNumber#] not found!" }, type="json" );
			}
		} else {
			event.renderData( data={ ok=false, message="Email queue heartbeat is not enabled on this application instance." }, type="json" );
		}

	}

	public void function startAssetQueueHeartbeat( event, rc, prc ) {
		if ( isFeatureEnabled( "assetQueue" ) && isFeatureEnabled( "assetQueueHeartBeat" ) ) {
			var instanceNumber = Val( rc.instanceNumber ?: "" );

			if ( instanceNumber > 0 && instanceNumber <= assetQueueConcurrency ) {
				getModel( "AssetQueueHeartBeat#instanceNumber#" ).start();
				event.renderData( data={ ok=true }, type="json" );
			} else {
				event.renderData( data={ ok=false, message="Queue heartbeat instance [#instanceNumber#] not found!" }, type="json" );
			}
		} else {
			event.renderData( data={ ok=false, message="Asset queue heartbeat is not enabled on this application instance." }, type="json" );
		}

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