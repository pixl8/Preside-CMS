/**
 * Registry of custom field data types (controls, typed EAV columns, renderers).
 *
 * @singleton      true
 * @presideService true
 * @autodoc        true
 * @feature        customFields
 */
component {

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

	private struct function _getConfiguredTypes() {
		return _configuredTypes;
	}
	private void function _setConfiguredTypes( required struct configuredTypes ) {
		_configuredTypes = arguments.configuredTypes;
	}

}
