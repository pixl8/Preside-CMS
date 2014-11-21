component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @configuredFilters.inject coldbox:setting:filters
	 * @coldboxController.inject coldbox
	 *
	 */
	public any function init( required struct configuredFilters, required any coldboxController ) output=false {
		_setConfiguredFilters( arguments.configuredFilters );
		_setColdboxController( arguments.coldboxController );

		return this;
	}

// PUBLIC API METHODS
	public struct function getFilter( required string filterName, struct args={} ) output=false {
		var configuredFilters = _getConfiguredFilters();
		var filter            = configuredFilters[ arguments.filterName ] ?: {};

		if ( IsValid( "function", filter ) ) {
			filter = filter( arguments.args, _getColdboxController() );
		}

		if ( IsStruct( filter ) ) {
			if ( !filter.keyExists( "filter" ) && !filter.keyExists( "filterParams" ) ) {
				return { filter=filter, filterParams={} };
			}

			return {
				  filter       = filter.filter       ?: {}
				, filterParams = filter.filterParams ?: {}
			};
		}

		return {};
	}


// GETTERS AND SETTERS
	private struct function _getConfiguredFilters() output=false {
		return _configuredFilters;
	}
	private void function _setConfiguredFilters( required struct configuredFilters ) output=false {
		_configuredFilters = arguments.configuredFilters;
	}

	private any function _getColdboxController() output=false {
		return _coldboxController;
	}
	private void function _setColdboxController( required any coldboxController ) output=false {
		_coldboxController = arguments.coldboxController;
	}

}