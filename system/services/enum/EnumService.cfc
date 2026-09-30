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
		_setEnumTranslations( {} );

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
				, label       = translate( enum=arguments.enum, key=itemId, property="label" )
				, description = translate( enum=arguments.enum, key=itemId, property="description" )
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
					enumValue[ propName ] = translate( enum=arguments.enum, key=key, property=propName );
				}

				enumProps[ key ] = enumValue;
			}
		}

		return enumProps;
	}

	public string function getLabelByKey( required string enum, required string key ) {
		return translate( enum=arguments.enum, key=arguments.key, property="label" );
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

	public array function fuzzySearchKeyByLabel( required string enum, required string searchTerm ) {
		var result = [];
		var items  = listItems( arguments.enum );

		for ( var item in items ) {
			if ( findNoCase( arguments.searchTerm, item.label ) ) {
				result.append( item.id );
			}
		}

		return result;
	}

	/**
	 * Registers (or replaces) an enum and optional per-property i18n URI templates.
	 * Templates may include `{key}` and `{enum}` placeholders. When a property has
	 * no template, translations fall back to `enum.{enum}:{key}.{property}`.
	 *
	 * @autodoc            true
	 * @enum.hint          ID of the enum to register
	 * @keys.hint          Array of enum item keys, in display order
	 * @translations.hint  Struct of property name to URI template, e.g. `{ label="preside-objects.{key}:title" }`
	 *
	 */
	public void function registerEnum(
		  required string enum
		, required array  keys
		,          struct translations = {}
	) {
		var configuredEnums  = _getConfiguredEnums();
		var enumTranslations = _getEnumTranslations();

		configuredEnums[ arguments.enum ]  = arguments.keys;
		enumTranslations[ arguments.enum ] = Duplicate( arguments.translations );
	}

	/**
	 * Translates an enum item property, using any URI template registered
	 * for the enum or the default `enum.{enum}:{key}.{property}` pattern.
	 *
	 * @autodoc             true
	 * @enum.hint           ID of the enum
	 * @key.hint            Enum item key
	 * @property.hint       i18n property, e.g. label, description, iconClass
	 * @defaultValue.hint   Fallback when the resource is missing. Defaults to the key for `label`, otherwise empty string
	 * @data.hint           Optional data array passed through to translateResource
	 *
	 */
	public string function translate(
		  required string enum
		, required string key
		, required string property
		,          string defaultValue
		,          array  data = []
	) {
		if ( !StructKeyExists( arguments, "defaultValue" ) ) {
			arguments.defaultValue = ( arguments.property == "label" ? arguments.key : "" );
		}

		var translateArgs = {
			  uri          = getTranslationUri( argumentCollection=arguments )
			, defaultValue = arguments.defaultValue
			, data         = arguments.data
		};

		return $translateResource( argumentCollection=translateArgs );
	}

	public string function getTranslationUri(
		  required string enum
		, required string key
		, required string property
	) {
		var templates = _getEnumTranslations();
		var template  = "";

		if ( StructKeyExists( templates, arguments.enum ) ) {
			template = templates[ arguments.enum ][ arguments.property ] ?: "";
		}

		if ( Len( template ) ) {
			return Replace( Replace( template, "{key}", arguments.key, "all" ), "{enum}", arguments.enum, "all" );
		}

		return "enum.#arguments.enum#:#arguments.key#.#arguments.property#";
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

	private struct function _getEnumTranslations() {
		return _enumTranslations;
	}
	private void function _setEnumTranslations( required struct enumTranslations ) {
		_enumTranslations = arguments.enumTranslations;
	}
}
