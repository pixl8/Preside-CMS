/**
 * Provides logic for the system of per-object and global
 * customizations of datamanager
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
	 * Returns the handler by either convention or configuration
	 * for the given object that will provide any customizations
	 * for the object
	 *
	 * @autodoc    true
	 * @objectName Name of the object
	 */
	public string function getCustomizationHandlerForObject( required string objectName ) {
		var customHandler  = $getPresideObjectService().getObjectAttribute( arguments.objectName, "dataManagerHandler" );
		var defaultHandler = "admin.datamanager." & arguments.objectName;

		return customHandler.len() ? customHandler : defaultHandler;
	}

	/**
	 * Returns the global handler to use when object does not have
	 * its own customizations
	 *
	 * @autodoc true
	 */
	public string function getGlobalCustomizationHandler() {
		return "admin.datamanager.GlobalCustomizations";
	}

	/**
	 * Returns the full coldbox event path for a given object and
	 * customization action
	 *
	 * @autodoc    true
	 * @objectName Name of the object
	 * @action     Name of the customization action
	 */
	public string function getCustomizationEventForObject(
		  required string objectName
		, required string action
	) {
		var event = arguments.objectName.len() ? ( getCustomizationHandlerForObject( arguments.objectName ) & "." & arguments.action ) : "";

		if ( !$getColdbox().handlerExists( event ) ) {
			event = getGlobalCustomizationEvent( arguments.action );
		}

		return event;
	}

	/**
	 * Returns the full coldbox event path for the given
	 * customization action
	 *
	 * @autodoc    true
	 * @action     Name of the customization action
	 */
	public string function getGlobalCustomizationEvent( required string action ) {
		var event = getGlobalCustomizationHandler() & "." & arguments.action;

		return $getColdbox().handlerExists( event ) ? event : "";
	}

	/**
	 * Returns whether or not an object has the given customization
	 *
	 * @autodoc    true
	 * @objectName Name of the object
	 * @action     Name of the customization action
	 */
	public boolean function objectHasCustomization(
		  required string objectName
		, required string action
	) {
		return getCustomizationEventForObject( arguments.objectName, arguments.action ).len() > 0;
	}

	/**
	 * Runs the coldbox event for the given object/customization action
	 *
	 * @autodoc        true
	 * @objectName     Name of the object
	 * @action         Name of the customization action
	 * @args           Args struct to pass through to the customization handler action
	 * @defaultHandler Default handler to run should the object not have its own
	 */
	public any function runCustomization(
		  required string objectName
		, required string action
		,          struct args = {}
		,          string defaultHandler = ""
	) {
		var event = "";

		if ( arguments.objectName.len() ) {
			event = getCustomizationEventForObject( arguments.objectName, arguments.action );
		} else {
			event = getGlobalCustomizationEvent( arguments.action );
		}

		if ( !event.len() ) {
			event = defaultHandler;
		}

		if ( Len( Trim( event ) ) ) {
			return $getColdbox().runEvent(
				  event          = event
				, private        = true
				, prePostExempt  = true
				, eventArguments = { args=arguments.args }
			);
		}
	}

// PRIVATE HELPERS
	private any function _simpleLocalCache( required string cacheKey, required any provider ) {
		if ( !StructKeyExists( variables, arguments.cacheKey ) ) {
			variables[ arguments.cacheKey ] = arguments.provider();
		}

		return variables[ arguments.cacheKey ];
	}

}