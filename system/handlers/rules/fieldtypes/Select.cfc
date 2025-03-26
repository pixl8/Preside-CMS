/**
 * Handler for rules engine 'select type'
 *
 * @feature rulesEngine
 */
component {

	private string function renderConfiguredField( string value="", struct config={} ) {
		var values = config.values ?: [];
		var labels = config.labels ?: [];

		if ( IsSimpleValue( values ) ) {
			values = ListToArray( values );
		}

		if ( IsSimpleValue( labels ) ) {
			labels = ListToArray( labels );
		}

		labels = _getLabels( values, labels, config.labelUriRoot ?: "" );

		var items  = [];
		for ( var value in ListToArray( arguments.value ) ) {
			var index = ArrayFindNoCase( values, value );

			if ( index ) {
				ArrayAppend( items, labels[ index ] );
			}
		}

		if ( !ArrayLen( items ) ) {
			return config.defaultLabel ?: translateResource( "cms:rulesEngine.fieldtype.select.default.label" )
		}

		return ArrayToList( items, ", " );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var values = config.values ?: [];
		var labels = config.labels ?: [];

		if ( IsSimpleValue( values ) ) {
			values = ListToArray( values );
		}

		if ( IsSimpleValue( labels ) ) {
			labels = ListToArray( labels );
		}

		labels = _getLabels( values, labels, config.labelUriRoot ?: "" );

		var multiple = IsTrue( config.multiple ?: true );
		var sortable = IsTrue( config.sortable ?: true );

		StructDelete( rc, "value" );

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
	private array function _getLabels( required array values, array labels=[], string labelUriRoot="" ) {
		if ( ArrayLen( arguments.values ) && !ArrayLen( arguments.labels ) ) {
			if ( isEmptyString( arguments.labelUriRoot ) ) {
				arguments.labels = arguments.values;
			} else {
				for ( var value in arguments.values ) {
					ArrayAppend( arguments.labels, translateResource( uri="#labelUriRoot##value#" ) );
				}
			}
		}

		return arguments.labels;
	}

}