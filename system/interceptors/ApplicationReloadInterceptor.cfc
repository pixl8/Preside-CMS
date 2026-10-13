component extends="coldbox.system.Interceptor" {

	property name="enums" inject="coldbox:setting:enum";

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

		_tweaksForFeatures()
	}

	public void function afterInstanceAutowire( event, interceptData ) {
		if ( StructKeyExists( arguments.interceptData.target, "postInit" ) ) {
			arguments.interceptData.target.postInit();
		}
	}

// PRIVATE HELPERS
	private void function _tweaksForFeatures() {
		if ( !isFeatureEnabled( "sitetree" ) ) {
			ArrayDelete( enums.linkType, "sitetreelink" );
		}
		if ( !isFeatureEnabled( "assetManager" ) ) {
			ArrayDelete( enums.linkType, "asset" );
		}
	}
}