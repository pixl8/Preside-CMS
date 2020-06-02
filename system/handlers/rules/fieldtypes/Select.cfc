/**
 * Handler for rules engine 'select type'
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var values        = ListToArray( config.values ?: "" );
		var labels        = _getLabels( config );
		var items         = [];

		for( var v in ListToArray( arguments.value ) ) {
			var index = values.findNoCase( v );
			if ( index ) {
				items.append( labels[ index ] );
			}
		}

		if( items.isEmpty() ) {
			return config.defaultLabel ?: translateResource( "cms:rulesEngine.fieldtype.select.default.label" )
		}

		return items.toList( ", " );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var values        = ListToArray( config.values ?: "" );
		var labels        = _getLabels( config );
		var multiple      = IsTrue( config.multiple ?: true );
		var sortable      = IsTrue( config.sortable ?: true );

		rc.delete( "value" );

		return renderFormControl(
			  name         = "value"
			, type         = "select"
			, multiple     = multiple
			, sortable     = sortable
			, label        = translateResource( config.fieldLabel ?: "cms:rulesEngine.fieldtype.select.config.label" )
			, values       = values
			, labels       = labels
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, required     = true
		);
	}

// helpers
	private array function _getLabels( config ) {
		var values        = ListToArray( config.values ?: "" );
		var labels        = ListToArray( config.labels ?: "" );
		var labelUriRoot  = config.labelUriRoot ?: "";

		if ( values.len() && !labels.len() ) {
			if ( labelUriRoot.len() ) {
				for( var value in values ) {
					labels.append( translateResource( labelUriRoot & value ) );
				}
			} else {
				labels = values;
			}
		}

		return labels;
	}

}