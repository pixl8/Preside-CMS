component extends="coldbox.system.Interceptor" {

	public void function configure() {}

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

	public void function afterInstanceAutowire( event, interceptData ) {
		if ( StructKeyExists( arguments.interceptData.target, "postInit" ) ) {
			arguments.interceptData.target.postInit();
		}
	}
}