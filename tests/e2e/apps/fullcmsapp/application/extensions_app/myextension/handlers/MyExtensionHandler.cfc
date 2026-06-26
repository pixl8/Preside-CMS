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

		if ( isExtensionInstalled( "myextension" ) ) {
			event.renderData( data=myExtensionService.test(), type="json" );
		} else {
			event.renderData( data={ testpassed=false }, type="json" );
		}

	}

	function customTags() {
		var output = "";

		savecontent variable="output" {
			include "/application/extensions_app/myextension/views/customtags/index.cfm";
		}

		event.renderData( data=output, type="plain" );
	}

}