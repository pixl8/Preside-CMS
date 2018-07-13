component extends="coldbox.system.Interceptor" {

	property name="taskmanagerService" inject="delayedInjector:taskmanagerService";
	property name="errorLogService"    inject="delayedInjector:errorLogService";

// PUBLIC
	public void function configure() output=false {}

	public void function onPresideHeartbeat( event, interceptData ) output=false {
		try {
			var result = taskmanagerService.runScheduledTasks();

			if ( Len( Trim( result.error ) ) ) {
				throw( type="preside.taskmanager.configuration", message=result.error );
			}
		} catch( any e ) {
			errorLogService.raiseError( e );
		}
	}
}
