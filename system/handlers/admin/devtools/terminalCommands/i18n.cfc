component hint="Manage Preside i18n" extends="preside.system.base.Command" {

	property name="jsonRpc2"             inject="JsonRpc2";
	property name="i18n"                 inject="i18n";
	property name="presideObjectService" inject="PresideObjectService";

	private function index( event, rc, prc ) {
		var params          = jsonRpc2.getRequestParams();
		var validOperations = [ "object" ];

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !ArrayLen( params ) || !ArrayFindNoCase( validOperations, params[ 1 ] ) ) {
			var message = newLine();

			message &= writeText( text="Usage: ", type="info", bold=true );
			message &= writeText( "i18n [operation]" );
			message &= newLine();

			message &= writeText( "Valid operations:" );
			message &= newLine();

			message &= writeText( text="    object ", type="info", bold=true );
			message &= writeText( text=": Lists all i18n properties of an object." );

			return message;
		}

		return runEvent(
			  event          = "admin.devtools.terminalCommands.i18n.#params[ 1 ]#"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				args = {
					params = params
				}
			  }
		);
	}

	private any function object( event, rc, prc, args ) {
		var message = newLine();
		var titles  = "";

		var objectName = args.params[ 2 ] ?: "";

		var rows  = [];
		var props = presideObjectService.getObjectProperties( objectName=objectName );

		for ( var propertyName in props ) {
			var cols       = [];
			var uri        = presideObjectService.getResourceBundleUriRoot( objectName=objectName ) & "field.#propertyName#.title";
			var translated = i18n.translateResource( uri=uri, defaultValue="" );
			var type       = isEmptyString( translated ) ? "error" : "";

			ArrayAppend( cols, {
				  text = propertyName
				, type = type
			} );
			ArrayAppend( cols, {
				  text = uri
				, type = type
			} );
			ArrayAppend( cols, {
				  text = isEmptyString( translated ) ? "(no value)" : translated
				, type = type
			} );

			ArrayAppend( rows, cols );
		}

		return newTable(
			  header = [ "Property", "URI", "Translation" ]
			, rows   = rows
		);
	}

}