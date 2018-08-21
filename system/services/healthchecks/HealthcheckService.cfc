/**
 * Service to provide healthcheck functionality for external
 * services (i.e. elasticsearch, etc.).
 *
 * @autodoc        true
 * @presideService true
 * @singleton      true
 */
component {

	variables._services = {};

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
	public array function listRegisteredServices() {
		var services = _getRegisteredServices();

		if ( IsNull( services ) ) {
			var possibleHandlers = $getColdbox().listHandlers( thatStartWith="healthcheck." );

			services = [];
			for( var possibleHandler in possibleHandlers ) {
				if ( ListLen( possibleHandler, "." ) == 2 ) {
					services.append( ListLast( possibleHandler, "." ) );
				}
			}

			_setRegisteredServices( services );
		}

		return services;
	}

	/**
	 * Returns whether or not the given service exists
	 *
	 * @autodoc true
	 * @serviceId ID of the service to check
	 *
	 */
	public boolean function serviceExists( required string serviceId ) {
		return listRegisteredServices().findNoCase( arguments.serviceId );
	}

	/**
	 * Checks the given service. Returning true if the service's healthcheck
	 * returns true, false if it returns false, errors or does not return
	 * a boolean value.
	 *
	 * @autodoc   true
	 * @serviceid ID of the service to check
	 *
	 */
	public boolean function checkService( required string serviceId ) {
		if ( !serviceExists( arguments.serviceId ) ) {
			return false;
		}

		var event = "healthcheck.#arguments.serviceId#.check";

		try {
			var result = $getColdbox().runEvent(
				  event         = event
				, private       = true
				, prepostExempt = true
			);
		} catch( any e ) {
			$raiseError( e );
			setIsUp( arguments.serviceId, false );
			return false;
		}

		setIsUp( arguments.serviceId, IsBoolean( result ) && result );
		return IsBoolean( result ) && result;
	}

	/**
	 * Returns whether or not the given service is up
	 * according to the last check made
	 *
	 * @autodoc   true
	 * @serviceId ID of the service to check
	 */
	public boolean function isUp( required string serviceId ) {
		return serviceExists( arguments.serviceId ) && ( variables._services[ arguments.serviceId ] ?: false );
	}

	/**
	 * Sets whether or not the given service is 'up'
	 *
	 * @autodoc   true
	 * @serviceId ID of the service whose status you wish to set
	 * @isUp      Whether or not the service is up
	 */
	public void function setIsUp( required string serviceId, required boolean isUp ) {
		variables._services[ arguments.serviceId ] = arguments.isUp;
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getRegisteredServices() {
		return _registeredServices ?: NullValue();
	}
	private void function _setRegisteredServices( required any registeredServices ) {
		_registeredServices = arguments.registeredServices;
	}

}