component {

	property name="myExtensionService" inject="myExtensionService";
	property name="myEtensionSp"       inject="myAppExtensionStorageProvider";
	property name="myExtensionCache"   inject="cachebox:myAppExtensionCache";

	function index() {
		if ( StructKeyExists( rc, "e2etesterror" ) ) {
			try {
				throw( type="test.e2e.error.handling" );
			} catch( any e ) {
				logError( e );
			}
		}
		event.renderData( data=myExtensionService.test(), type="json" );
	}

}