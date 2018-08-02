/**
 * Service to provide healthcheck functionality for external
 * services (i.e. elasticsearch, etc.).
 *
 * @autodoc        true
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	/**
	 * Reads healthcheck services by examinig coldbox
	 * handlers that match the pattern healthcheck.myservice
	 * where myservice is the handler cfc and the ID of the
	 * service to monitor.
	 *
	 * @autodoc true
	 */
	public array function readServicesFromHandlers() {
		var possibleHandlers = $getColdbox().listHandlers( thatStartWith="healthcheck." );
		var services         = [];

		for( var possibleHandler in possibleHandlers ) {
			if ( ListLen( possibleHandler, "." ) == 2 ) {
				services.append( ListLast( possibleHandler, "." ) );
			}
		}

		return services;
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS

}