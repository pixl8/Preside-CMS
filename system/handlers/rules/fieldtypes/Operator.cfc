/**
 * Handler for rules engine 'operator type'
 *
 */
component {

	_varietyMappings = {};
	_varietyMappings[ "string"  ] = [ "eq", "neq", "contains", "notcontains", "startswith", "notstartswith", "endswith", "notendswith" ];
	_varietyMappings[ "numeric" ] = [ "eq", "neq", "gt", "gte", "lt", "lte" ];
	_varietyMappings[ "date"    ] = [ "eq", "neq", "gt", "gte", "lt", "lte" ];
	_varietyMappings[ "period"  ] = [ "eq", "gt", "gte", "lt", "lte" ];

	private string function renderConfiguredField( string value="", struct config={} ) {
		var variety = "string";

		switch( config.variety ?: "" ) {
			case "date":
			case "numeric":
			case "period":
				variety = config.variety;
		}

		return translateResource( uri="cms:rulesEngine.operator.#variety#.#value#" );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var variety = "string";

		switch( config.variety ?: "" ) {
			case "date":
			case "numeric":
			case "period":
				variety = config.variety;
		}

		var values = _varietyMappings[ variety ];
		var labels = [];

		for( var operatorValue in values ){
			labels.append( translateResource( uri="cms:rulesEngine.operator.#variety#.#operatorValue#" ) );
		}

		rc.delete( "value" );

		return renderFormControl(
			  name         = "value"
			, type         = "select"
			, values       = values
			, labels       = labels
			, label        = translateResource( "cms:rulesEngine.fieldtype.operator.config.label" )
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, required     = true
		);
	}

}