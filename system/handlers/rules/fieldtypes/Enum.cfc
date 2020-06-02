/**
 * Handler for rules engine 'enum' field type
 *
 */
component {

	property name="enumService" inject="enumService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var values = arguments.value.listToArray();
		var labels = [];
		var items = enumService.listItems( config.enum ?: "" );

		for( var item in items ) {
			if ( values.findNoCase( item.id ) ) {
				labels.append( item.label );
			}
		}

		if ( labels.len() ) {
			return labels.toList( ", " );
		}

		return translateResource( config.defaultLabel ?: "cms:rulesEngine.fieldtype.enum.default.label", ( config.defaultLabel ?: "" ) );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		rc.delete( "value" );

		return renderFormControl(
			  argumentCollection = config
			, name               = "value"
			, type               = "enumSelect"
			, multiple           = IsTrue( arguments.config.multiple ?: true )
			, label              = translateResource( config.fieldLabel ?: "cms:rulesEngine.fieldtype.enum.config.label" )
			, savedValue         = arguments.value
			, defaultValue       = arguments.value
			, required           = true
		);
	}
}