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
	/**
	 * @configuredServices.inject coldbox:setting:healthcheckServices
	 *
	 */
	public any function init( required struct configuredServices ) {
		_setConfiguredServices( arguments.configuredServices );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns configured services whose health
	 * will be periodically checked.
	 *
	 * @autodoc true
	 */
	public array function listRegisteredServices() {
		return StructKeyArray( _getConfiguredServices() );
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

		try {
			var result = $getColdbox().runEvent(
				  event         = _getHealthCheckHandlerEvent( arguments.serviceId )
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

	/**
	 * Gets a struct of services whose keys are the service IDs
	 * and values their boolean up status
	 *
	 * @autodoc
	 *
	 */
	public struct function getAllStatuses() {
		var statuses = {};

		for( var serviceId in _getConfiguredServices() ) {
			statuses[ serviceId ] = isUp( serviceId );
		}

		return statuses;
	}

// PRIVATE HELPERS
	private string function _getHealthCheckHandlerEvent( required string serviceId ) {
		var svc = _getConfiguredServices()[ arguments.serviceId ];

		return svc.handler ?: "healthcheck.#arguments.serviceId#.check";
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredServices() {
		return _configuredServices;
	}
	private void function _setConfiguredServices( required struct configuredServices ) {
		_configuredServices = arguments.configuredServices;
	}
}