/**
 * Provides logic around interacting with configured form builder item types
 *
 * @singleton
 * @presideservice
 * @autodoc
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @configuredTypesAndCategories.inject coldbox:setting:formbuilder.itemtypes
	 *
	 */
	public any function init( required struct configuredTypesAndCategories ) {
		_setConfiguredTypesAndCategories( arguments.configuredTypesAndCategories );

		return this;
	}

// PUBLIC API
	/**
	 * Returns an array of item categories each with child
	 * item types. Categories ordered by defined sort order
	 * and item types ordered by defined sort order
	 *
	 * @autodoc
	 */
	public array function getItemTypesByCategory() {
		var configured = _getConfiguredTypesAndCategories();
		var categories = [];

		for( var categoryId in configured ) {
			var category = {
				  id        = categoryId
				, title     = $translateResource( uri="formbuilder.item-categories:#categoryId#.title", defaultValue=categoryId )
				, types     = []
			};
			var types = configured[ categoryId ].types ?: {};

			for( var typeId in types ) {
				var type = types[ typeId ];

				type.id    = typeId;
				type.title = $translateResource( uri="formbuilder.item-types.#typeId#:title", defaultValue=typeId );

				category.types.append( type );

				type.isFormField = IsBoolean( type.isFormField ?: "" ) ? type.isFormField : true;
			}

			category.types.sort( function( a, b ){
				return a.title > b.title ? 1 : -1;
			} );

			categories.append( category );
		}

		categories.sort( function( a, b ){
			var orderA = configured[ a.id ].sortOrder ?: 10000;
			var orderB = configured[ b.id ].sortOrder ?: 10000;

			return orderA > orderB ? 1 : -1;
		} );

		return categories;
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private struct function _getConfiguredTypesAndCategories() {
		return _configuredTypesAndCategories;
	}
	private void function _setConfiguredTypesAndCategories( required struct configuredTypesAndCategories ) {
		_configuredTypesAndCategories = arguments.configuredTypesAndCategories;
	}

}