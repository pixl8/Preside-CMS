/**
 * Provides logic for dealing with rules engine contexts.
 *
 * See [[rules-engine]] for more details.
 *
 * @singleton
 * @presideservice
 * @autodoc
 *
 */
component displayName="RulesEngine Context Service" {

// CONSTRUCTOR
	/**
	 * @configuredContexts.inject coldbox:setting:rulesEngine.contexts
	 *
	 */
	public any function init( required struct configuredContexts ) {
		_setConfiguredContexts( arguments.configuredContexts );

		return this;
	}


// PUBLIC API
	public array function listContexts() {
		var contexts = _getConfiguredContexts();
		var list     = [];

		for( var contextId in contexts ) {
			list.append({
				  id          = contextId
				, title       = $translateResource( "rules.contexts:#contextId#.title"       )
				, description = $translateResource( "rules.contexts:#contextId#.description" )
				, iconClass   = $translateResource( "rules.contexts:#contextId#.iconClass"   )
			});
		}

		list.sort( function( a, b ){
			return a.title > b.title ? 1 : -1;
		} );

		return list;
	}


// GETTERS AND SETTERS
	private struct function _getConfiguredContexts() {
		return _configuredContexts;
	}
	private void function _setConfiguredContexts( required struct configuredContexts ) {
		_configuredContexts = arguments.configuredContexts;
	}

}