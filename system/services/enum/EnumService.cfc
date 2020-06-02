/**
 * Encapsulates logic for Preside's ENUM system.
 *
 * @autodoc        true
 * @presideservice true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @configuredEnums.inject coldbox:setting:enum
	 *
	 */
	public any function init( required struct configuredEnums ) {
		_setConfiguredEnums( arguments.configuredEnums );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns an array of items for the given enum. Each item is a
	 * struct with id, label and description keys (label and description)
	 * are translated on the fly. The order of the items obeys the order in
	 * which they were defined in the enum.
	 *
	 * @autodoc   true
	 * @enum.hint ID of the enum whose items you wish to list
	 *
	 */
	public array function listItems( required string enum ) {
		var enums                          = _getConfiguredEnums();
		var rawItems                       = enums[ arguments.enum ] ?: [];
		var itemsWithLabelsAndDescriptions = [];

		for( var itemId in rawItems ) {
			itemsWithLabelsAndDescriptions.append({
				  id          = itemId
				, label       = $translateResource( uri="enum.#arguments.enum#:#itemId#.label"      , defaultValue=itemId )
				, description = $translateResource( uri="enum.#arguments.enum#:#itemId#.description", defaultValue=""     )
			});
		}

		return itemsWithLabelsAndDescriptions;
	}

	public struct function getEnumProperties( required string enum, array restrictToKeys=[], array properties=[ "label", "description" ] ) {
		var enums     = _getConfiguredEnums();
		var enumKeys  = enums[ arguments.enum ] ?: [];
		var enumProps = {};

		for( var key in enumKeys ) {
			if ( !ArrayLen( restrictToKeys ) || ArrayFindNoCase( restrictToKeys, key ) ) {
				var enumValue = {};
				for( var propName in arguments.properties ) {
					enumValue[ propName ] = $translateResource(
						  uri          = "enum.#arguments.enum#:#key#.#propName#"
						, defaultValue = ( propName == "label" ? key : "" )
					);
				}

				enumProps[ key ] = enumValue;
			}
		}

		return enumProps;
	}

	public string function getLabelByKey( required string enum, required string key ) {
		return $translateResource( uri="enum.#arguments.enum#:#arguments.key#.label", defaultValue=arguments.key );
	}

	public string function getKeyByLabel( required string enum, required string label ) {
		var enums    = _getConfiguredEnums();
		var enumKeys = enums[ arguments.enum ] ?: [];

		for( var key in enumKeys ) {
			if ( getLabelByKey( arguments.enum, key ) == arguments.label ) {
				return key;
			}
		}

		return "";
	}


	/**
	 * @validator        true
	 * @validatorMessage cms:validation.enum.default
	 */
	public boolean function enum(
		  required string  fieldName
		, required any     value
		, required string  enum
		,          boolean multiple = false
	) {
		if ( !IsSimpleValue( arguments.value ) || !Len( Trim( arguments.value ) ) ) {
			return true;
		}

		var enums    = _getConfiguredEnums();
		var rawItems = enums[ arguments.enum ] ?: [];

		if ( arguments.multiple ) {
			for( var v in ListToArray( arguments.value ) ) {
				if ( !rawItems.find( v ) ) {
					return false;
				}
			}

			return true;
		}

		return rawItems.find( arguments.value );
	}

	public string function enum_js() {
		// server side validation only for now
		return "function( value, elem, params ){ return true; }";
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private struct function _getConfiguredEnums() {
		return _configuredEnums;
	}
	private void function _setConfiguredEnums( required struct configuredEnums ) {
		_configuredEnums = arguments.configuredEnums;
	}
}