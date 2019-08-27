/**
 * @singleton      true
 * @presideService true
 */
component {

// CONSTRUCTOR
	/**
	 * @configuredFilters.inject coldbox:setting:filters
	 *
	 */
	public any function init( required struct configuredFilters ) {
		_setConfiguredFilters( arguments.configuredFilters );

		return this;
	}

// PUBLIC API METHODS
	public struct function getFilter( required string filterName, struct args={} ) {
		var configuredFilters = _getConfiguredFilters();
		var filter            = "";


		if ( StructKeyExists( configuredFilters, arguments.filterName ) ) {
			filter = configuredFilters[ arguments.filterName ];

			if ( IsValid( "function", filter ) ) {
				filter = filter( arguments.args, $getColdbox() );
			}
		} else {
			filter = _runHandlerFilter( arguments.filterName, arguments.args );
		}

		if ( IsStruct( filter ) ) {
			if ( !StructKeyExists( filter, "filter" ) && !StructKeyExists( filter, "filterParams" ) ) {
				return { filter=filter, filterParams={} };
			}

			return {
				  filter       = filter.filter       ?: {}
				, filterParams = filter.filterParams ?: {}
			};
		}

		return {};
	}

// PRIVATE HELPERS
	private any function _runHandlerFilter( required string filterName, required struct args ) {
		var handler = "dataFilters.#arguments.filterName#";
		var cb      = $getColdbox();

		if ( cb.handlerExists( handler ) ) {
			var result = cb.runEvent(
				  event          = handler
				, eventArguments = { args=args }
				, private        = true
				, prePostExempt  = true
			);

			return local.result ?: {};
		}

		return {};
	}


// GETTERS AND SETTERS
	private struct function _getConfiguredFilters() {
		return _configuredFilters;
	}
	private void function _setConfiguredFilters( required struct configuredFilters ) {
		_configuredFilters = arguments.configuredFilters;
	}
}