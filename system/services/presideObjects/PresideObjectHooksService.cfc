/**
 * Service that provides proxy logic to preside object
 * 'hook' handlers. See [[objecthooks]].
 *
 * @presideService true
 * @singleton      true
 * @autodoc        true
 */
component displayName="Preside Object Hooks Service"{

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns the conventions based coldbox event name
	 * for the given objectname and hook.
	 *
	 * @autodoc true
	 * @objectName Name of the object whose hook event you want to get
	 * @hook       Name of the hook whose event you want to get
	 *
	 */
	public string function getColdboxEventForHook(
		  required string objectName
		, required string hook
	) {
		return "preside-object-hooks.#arguments.objectName#.#arguments.hook#";
	}

	/**
	 * Returns whether or not the given hook exists for the given object
	 *
	 * @autodoc    true
	 * @objectName Name of the object whose hook you wish to verify
	 * @hook       Name of the hook to verify
	 *
	 */
	public boolean function hasHook(
		  required string objectName
		, required string hook
	) {
		var event = getColdboxEventForHook( arguments.objectName, arguments.hook );

		return $getColdbox().handlerExists( event );
	}

	/**
	 * Calls the hook for the given object, passing in any args supplied.
	 * Will return whatever value is returned by the hook
	 *
	 * @autodoc    true
	 * @objectName Name of the object whose hook you wish to call
	 * @hook       Name of the hook to call
	 * @args       Optional struct of args to pass to the hook handler
	 *
	 */
	public any function callHook(
		  required string objectName
		, required string hook
		,          struct args = {}
	) {
		return $getColdbox().runEvent(
			  event          = getColdboxEventForHook( arguments.objectName, arguments.hook )
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=arguments.args }
		);
	}


// PRIVATE HELPERS

// GETTERS AND SETTERS

}