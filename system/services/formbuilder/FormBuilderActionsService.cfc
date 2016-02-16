/**
 * Provides logic around actions in form builder
 *
 * @autodoc
 * @singleton
 * @presideservice
 */
component {

// CONSTRUCTOR
	/**
	 * @configuredActions.inject coldbox:setting:formbuilder.actions
	 *
	 */
	public any function init( required array configuredActions ) {
		_setConfiguredActions( arguments.configuredActions );

		return this;
	}

// PUBLIC API
	/**
	 * Returns an array of actions that are registered
	 * with the system. Each action will consist of
	 * id, title, description and iconClass keys
	 *
	 * @autodoc
	 *
	 */
	public array function listActions() {
		var configuredActions = _getConfiguredActions();
		var actions           = [];

		for( var action in configuredActions ) {
			actions.append({
				  id          = action
				, title       = $translateResource( uri="formbuilder.actions.#action#:title"      , defaultValue=action    )
				, description = $translateResource( uri="formbuilder.actions.#action#:description", defaultValue=""        )
				, iconClass   = $translateResource( uri="formbuilder.actions.#action#:iconclass"  , defaultValue="fa-send" )
			});
		}

		return actions;
	}


// GETTERS AND SETTERS
	private array function _getConfiguredActions() {
		return _configuredActions;
	}
	private void function _setConfiguredActions( required array configuredActions ) {
		_configuredActions = arguments.configuredActions;
	}
}
