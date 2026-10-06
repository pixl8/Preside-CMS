/**
 * Registry of custom field data types (controls, typed EAV columns, renderers).
 *
 * @singleton      true
 * @presideService true
 * @autodoc        true
 * @feature        customFields
 */
component {

	variables.MAX_DECIMAL_PLACES = 10;

	/**
	 * @configuredTypes.inject coldbox:setting:customFields.fieldTypes
	 */
	public any function init( required struct configuredTypes ) {
		_setConfiguredTypes( arguments.configuredTypes );

		return this;
	}

	public struct function getType( required string dataType ) {
		var types = _getConfiguredTypes();

		if ( StructKeyExists( types, arguments.dataType ) ) {
			var type = Duplicate( types[ arguments.dataType ] );
			type.id = arguments.dataType;
			return type;
		}

		return {
			  id          = arguments.dataType
			, control     = "textinput"
			, type        = "string"
			, typedColumn = "shorttext_value"
			, renderer    = "plaintext"
		};
	}

	public array function listTypes() {
		var types  = _getConfiguredTypes();
		var result = [];

		for( var id in types ) {
			var type = Duplicate( types[ id ] );
			type.id = id;
			ArrayAppend( result, type );
		}

		return result;
	}

	public string function getTypedColumn( required string dataType ) {
		return getType( arguments.dataType ).typedColumn ?: "shorttext_value";
	}

	public string function getControl( required string dataType ) {
		return getType( arguments.dataType ).control ?: "textinput";
	}

	public string function getRenderer( required string dataType ) {
		return getType( arguments.dataType ).renderer ?: "plaintext";
	}

	public string function getValueType( required string dataType ) {
		return getType( arguments.dataType ).type ?: "string";
	}

	public string function getDisplayGroup( required string dataType ) {
		switch( arguments.dataType ) {
			case "boolean":
				return "boolean";
			case "date":
			case "datetime":
				return "date";
			case "integer":
			case "float":
				return "number";
		}

		return "";
	}

	public struct function getDisplayConfig( required string dataType, any typeConfig="" ) {
		var defaults = _getDisplayDefaults( arguments.dataType );

		if ( StructIsEmpty( defaults ) ) {
			return {};
		}

		var stored = _deserializeTypeConfig( arguments.typeConfig );
		var config = Duplicate( defaults );

		for( var setting in defaults ) {
			if ( StructKeyExists( stored, setting ) ) {
				config[ setting ] = stored[ setting ];
			}
		}

		return _normaliseDisplayConfig( arguments.dataType, config, defaults );
	}

	public boolean function isDefaultDisplayConfig( required string dataType, required struct config ) {
		var defaults = _getDisplayDefaults( arguments.dataType );

		for( var setting in defaults ) {
			if ( ToString( arguments.config[ setting ] ?: "" ) != ToString( defaults[ setting ] ) ) {
				return false;
			}
		}

		return true;
	}

	public string function getDisplayRenderer( required string dataType ) {
		switch( getDisplayGroup( arguments.dataType ) ) {
			case "boolean":
				return "customFieldBoolean";
			case "date":
				return "customFieldDate";
			case "number":
				return "customFieldNumber";
		}

		return "";
	}

	public string function buildTypeConfig( required string dataType, required struct formData ) {
		if ( StructIsEmpty( _getDisplayDefaults( arguments.dataType ) ) ) {
			return "";
		}

		return SerializeJson( getDisplayConfig( dataType=arguments.dataType, typeConfig=arguments.formData ) );
	}

	public numeric function getMaxDecimalPlaces() {
		return MAX_DECIMAL_PLACES;
	}

	public struct function mapValueToTypedColumns( required string dataType, required any value ) {
		var mapped      = { field_value=ToString( arguments.value ?: "" ) };
		var typedColumn = getTypedColumn( arguments.dataType );

		if ( !Len( Trim( typedColumn ) ) ) {
			return mapped;
		}

		switch( typedColumn ) {
			case "int_value":
				mapped.int_value = IsNumeric( arguments.value ) ? Int( Val( arguments.value ) ) : "";
			break;
			case "float_value":
				mapped.float_value = IsNumeric( arguments.value ) ? Val( arguments.value ) : "";
			break;
			case "boolean_value":
				mapped.boolean_value = IsBoolean( arguments.value ) ? arguments.value : "";
			break;
			case "date_value":
				mapped.date_value = IsDate( arguments.value ) ? arguments.value : "";
			break;
			case "shorttext_value":
				mapped.shorttext_value = Left( ToString( arguments.value ?: "" ), 255 );
			break;
		}

		return mapped;
	}

	private struct function _getDisplayDefaults( required string dataType ) {
		switch( getDisplayGroup( arguments.dataType ) ) {
			case "boolean":
				return {
					  booleanDisplay = "checkCross"
					, trueLabel      = ""
					, trueColour     = ""
					, falseLabel     = ""
					, falseColour    = ""
					, unsetLabel     = ""
					, unsetColour    = ""
				};
			case "date":
				return { dateDisplay="systemDefault" };
			case "number":
				return {
					  numberDisplay = "standard"
					, decimalPlaces = ""
					, useGrouping   = true
					, prefix        = ""
					, suffix        = ""
				};
		}

		return {};
	}

	private struct function _normaliseDisplayConfig( required string dataType, required struct config, required struct defaults ) {
		var config = arguments.config;

		switch( getDisplayGroup( arguments.dataType ) ) {
			case "boolean":
				config.booleanDisplay = _oneOf( config.booleanDisplay, [ "yesNo", "trueFalse", "checkCross", "customBadge" ], arguments.defaults.booleanDisplay );

				for( var setting in [ "trueLabel", "trueColour", "falseLabel", "falseColour", "unsetLabel", "unsetColour" ] ) {
					config[ setting ] = _cleanString( config[ setting ] );
				}
			break;
			case "date":
				config.dateDisplay = _oneOf( config.dateDisplay, [ "systemDefault", "short", "medium", "long", "relative" ], arguments.defaults.dateDisplay );
			break;
			case "number":
				config.numberDisplay = _oneOf( config.numberDisplay, [ "standard", "currency", "percentage", "compact" ], arguments.defaults.numberDisplay );
				config.decimalPlaces = _cleanDecimalPlaces( config.decimalPlaces );
				config.useGrouping   = IsBoolean( config.useGrouping ) ? ( config.useGrouping ? true : false ) : arguments.defaults.useGrouping;
				config.prefix        = _cleanAffix( config.prefix );
				config.suffix        = _cleanAffix( config.suffix );
			break;
		}

		return config;
	}

	private struct function _deserializeTypeConfig( required any typeConfig ) {
		if ( IsStruct( arguments.typeConfig ) ) {
			return arguments.typeConfig;
		}
		if ( !IsSimpleValue( arguments.typeConfig ) || !Len( Trim( arguments.typeConfig ) ) || !IsJson( arguments.typeConfig ) ) {
			return {};
		}

		try {
			var parsed = DeserializeJson( arguments.typeConfig );

			return IsStruct( parsed ) ? parsed : {};
		} catch ( any e ) {
			return {};
		}
	}

	private string function _oneOf( required any value, required array allowed, required string defaultValue ) {
		var candidate = _cleanString( arguments.value );

		for( var option in arguments.allowed ) {
			if ( !Compare( option, candidate ) ) {
				return option;
			}
		}

		return arguments.defaultValue;
	}

	private string function _cleanDecimalPlaces( required any value ) {
		var places = _cleanString( arguments.value );

		if ( !Len( places ) || !IsNumeric( places ) ) {
			return "";
		}

		return ToString( Max( 0, Min( MAX_DECIMAL_PLACES, Int( Val( places ) ) ) ) );
	}

	private string function _cleanAffix( required any value ) {
		return IsSimpleValue( arguments.value ?: "" ) ? arguments.value : "";
	}

	private string function _cleanString( required any value ) {
		return IsSimpleValue( arguments.value ?: "" ) ? Trim( arguments.value ) : "";
	}

	private struct function _getConfiguredTypes() {
		return _configuredTypes;
	}
	private void function _setConfiguredTypes( required struct configuredTypes ) {
		_configuredTypes = arguments.configuredTypes;
	}

}
