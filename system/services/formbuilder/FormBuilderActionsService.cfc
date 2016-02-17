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
			actions.append(
				_getConventionsBasedActionConfiguration( action )
			);
		}

		return actions;
	}

	/**
	 * Returns the configuration of the given action
	 *
	 * @autodoc
	 * @action.hint The id of the action, e.g. 'email'
	 *
	 */
	public struct function getActionConfig( required string action ) {
		var configuredActions = _getConfiguredActions();

		if ( configuredActions.findNoCase( arguments.action ) ) {
			return _getConventionsBasedActionConfiguration( arguments.action );
		}

		return {};
	}

// PRIVATE HELPERS
	private struct function _getConventionsBasedActionConfiguration( required string action ) {
		return {
			  id             = arguments.action
			, configFormName = "formbuilder.actions." & arguments.action
			, title          = $translateResource( uri="formbuilder.actions.#arguments.action#:title"      , defaultValue=arguments.action )
			, description    = $translateResource( uri="formbuilder.actions.#arguments.action#:description", defaultValue=""               )
			, iconClass      = $translateResource( uri="formbuilder.actions.#arguments.action#:iconclass"  , defaultValue="fa-send"        )
		};
	}


// GETTERS AND SETTERS
	private array function _getConfiguredActions() {
		return _configuredActions;
	}
	private void function _setConfiguredActions( required array configuredActions ) {
		_configuredActions = arguments.configuredActions;
	}
}
