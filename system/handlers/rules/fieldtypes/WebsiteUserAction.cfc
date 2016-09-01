/**
 * Handler for rules engine 'websiteUserAction' type
 *
 */
component {

	property name="types" inject="coldbox:setting:websiteusers.actions";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var actions = arguments.value.trim().listToArray();
		var rendered = [];

		for( var action in actions ) {
			if ( ListLen( action, "." ) == 2 ) {
				rendered.append( _renderAction( ListFirst( action, "." ), ListRest( action, "." ) ) );
			}
		}

		if ( rendered.len() ) {
			return rendered.toList( ", " );
		}

		return config.defaultLabel ?: "";
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var multiple = IsTrue( config.multiple ?: true );
		var sortable = IsTrue( config.sortable ?: true );
		var values   = [];
		var labels   = [];
		var actions  = [];

		for( var type in types ){
			for( var action in types[type] ){
				actions.append( {
					  value = "#type#.#action#"
					, label = _renderAction( type, action )
				} );
			}
		}

		actions.sort( function( a, b ){
			return a.label > b.label ? -1 : 1;
		} );

		for( var action in actions ) {
			values.append( action.value );
			labels.append( action.label );
		}

		return renderFormControl(
			  name         = "value"
			, type         = "select"
			, multiple     = multiple
			, sortable     = sortable
			, values       = values
			, labels       = labels
			, label        = translateResource( "cms:rulesEngine.fieldtype.websiteUserAction.config.label" )
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, required     = true
		);
	}

// HELPERS
	private string function _renderAction( required string type, required string action ) {
		return translateResource( uri="websiteuser.actions:#type#.#action#", defaultValue=type & " " & action );
	}

}