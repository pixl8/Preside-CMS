/**
 * Provides logic for the system of per-object
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
		var cacheKey = "getCustomizationHandlerForObject#objectName#";
		var args     = arguments;

		return _simpleLocalCache( cacheKey, function(){
			var customHandler  = $getPresideObjectService().getObjectAttribute( args.objectName, "dataManagerHandler" );
			var defaultHandler = "datamanager." & args.objectName;

			return customHandler.len() ? customHandler : defaultHandler;
		} );
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
		return getCustomizationHandlerForObject( arguments.objectName ) & "." & arguments.action;
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
		var cacheKey = "objectHasCustomization" & arguments.objectName;
		var args     = arguments;

		return _simpleLocalCache( cacheKey, function(){
			return $getColdbox().handlerExists( getCustomizationEventForObject( args.objectName, args.action ) );
		} );
	}

	/**
	 * Runs the coldbox event for the given object/customization action
	 *
	 * @autodoc    true
	 * @objectName Name of the object
	 * @action     Name of the customization action
	 * @args       Args struct to pass through to the customization handler action
	 */
	public any function runCustomization(
		  required string objectName
		, required string action
		,          struct args = {}
	) {
		return $getColdbox().runEvent(
			  event          = getCustomizationEventForObject( arguments.objectName, arguments.action )
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=arguments.args }
		);
	}

// PRIVATE HELPERS
	private any function _simpleLocalCache( required string cacheKey, required any provider ) {
		if ( !variables.keyExists( arguments.cacheKey ) ) {
			variables[ arguments.cacheKey ] = provider();
		}

		return variables[ arguments.cacheKey ] ?: NullValue();
	}
// GETTERS AND SETTERS

}