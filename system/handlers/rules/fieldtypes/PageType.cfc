/**
 * Handler for rules engine 'pagetype type'
 *
 */
component {

	property name="pageTypesService" inject="pageTypesService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var types = ListToArray( arguments.value );

		for( var i=1; i<=types.len(); i++ ) {
			types[i] = translateResource( pageTypesService.getPageType( types[i] ).getName() );
		}

		return types.toList( ", " );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var multiple      = IsTrue( config.multiple ?: true );
		var sortable      = IsTrue( config.sortable ?: true );

		rc.delete( "value" );

		return renderFormControl(
			  name         = "value"
			, type         = "pageTypePicker"
			, multiple     = multiple
			, sortable     = sortable
			, label        = translateResource( "cms:rulesEngine.fieldtype.pagetype.config.label" )
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, required     = true
		);
	}

}