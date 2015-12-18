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
	 * Returns an array of item categories ordered by their translations
	 * for the current request and also containing each of their child
	 * item types, also ordered by their translations for the current
	 * request.
	 *
	 * @autodoc
	 */
	public array function getCategoriesAndItemTypes() {
		var configured = _getConfiguredTypesAndCategories();
		var categories = [];

		for( var categoryId in configured ) {
			var category = {
				  id    = categoryId
				, title = $translateResource( uri="formbuilder.item-categories:#categoryId#.title", defaultValue=categoryId )
			};

			categories.append( category );
		}

		categories.sort( function( a, b ){
			return a.title > b.title ? 1 : -1;
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