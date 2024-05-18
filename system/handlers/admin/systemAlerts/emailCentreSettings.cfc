/**
 * @feature admin and emailCenter
 */
component {

	private void function runCheck( required systemAlertCheck check ) {
		var issues = [];

		var defaultFromAddress = getSystemSetting( "email", "default_from_address", "" );
		if ( !Len( defaultFromAddress ) ) {
			ArrayAppend( issues, "defaultFromAddress" );
			check.setLevel( "critical" );
		}

		if ( ArrayLen( issues ) ) {
			check.fail();
			check.setData( { issues=issues } );
		}
	}

	private string function render( event, rc, prc, args={} ) {
		return renderView( view="/admin/systemAlerts/emailCentreSettings/render", args=args );
	}


// CONFIG SETTINGS
	private boolean function runAtStartup() {
		return true;
	}

	private array function watchSettingsCategories() {
		return [ "email" ];
	}

	private string function defaultLevel() {
		return "warning";
	}

}