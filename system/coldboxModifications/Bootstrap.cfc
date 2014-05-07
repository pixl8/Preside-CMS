component extends="coldbox.system.Coldbox" output="false" {

	public void function loadColdbox() output=false {
		var appKey     = super.locateAppKey();
		var controller = new Controller( COLDBOX_APP_ROOT_PATH, appKey );

		controller.getLoaderService().loadApplication( COLDBOX_CONFIG_FILE, COLDBOX_APP_MAPPING );

		if ( Len( controller.getSetting( "ApplicationStartHandler" ) ) ) {
			controller.runEvent( controller.getSetting( "ApplicationStartHandler" ), true );
		}

		StructDelete( application, appKey );
		application[ appKey ] = controller;
	}

	public boolean function onRequestStart( required string targetPage ) output=true {
		reloadChecks();

		if ( ReFindNoCase( 'index\.cfm$', arguments.targetPage ) ) {
			var content = "";

			savecontent variable="content" {
				processColdBoxRequest();
			}

			content = Trim( content );

			if ( Len( content ) ) {
				content reset=true;WriteOutput( content );return true;
			}
		}

		return true;
	}

	public string function getCOLDBOX_CONFIG_FILE() output=false {
		return variables.COLDBOX_CONFIG_FILE;
	}
	public string function getCOLDBOX_APP_ROOT_PATH() output=false {
		return variables.COLDBOX_APP_ROOT_PATH;
	}
	public string function getCOLDBOX_APP_KEY() output=false {
		return variables.COLDBOX_APP_KEY;
	}
	public string function getCOLDBOX_APP_MAPPING() output=false {
		return variables.COLDBOX_APP_MAPPING;
	}

}