component extends="coldbox.system.Interceptor" {

	property name="taskManagerService" inject="delayedInjector:taskmanagerService";

	public void function configure() {}

	public void function onApplicationStart( event ) output=false {
		taskManagerService.registerMasterScheduledTask();
	}

	public void function prePresideReload( event ) {
		var logger = getController().getLogBox().getLogger( "default" );
		if ( logger.canWarn() ) {
			logger.warn( "Application reloading now (reload requested)" );
		}
	}

	public void function postPresideReload( event ) {
		var logger = getController().getLogBox().getLogger( "default" );
		if ( logger.canWarn() ) {
			logger.warn( "Application reload complete" );
		}
	}
}