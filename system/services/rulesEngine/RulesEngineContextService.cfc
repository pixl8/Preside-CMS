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
	/**
	 * Returns an array with details of all configured rules engine expression contexts
	 *
	 * @autodoc
	 */
	public array function listContexts() {
		var contexts = _getConfiguredContexts();
		var list     = [];

		for( var contextId in contexts ) {
			var visible = !IsBoolean( contexts[ contextId ].visible ?: true ) ? true : ( contexts[ contextId ].visible ?: true );
			if ( visible ){
				list.append({
					  id           = contextId
					, title        = $translateResource( "rules.contexts:#contextId#.title"       )
					, description  = $translateResource( "rules.contexts:#contextId#.description" )
					, iconClass    = $translateResource( "rules.contexts:#contextId#.iconClass"   )
					, object       = contexts[ contextId ].object ?: ""
				});
			}
		}

		list.sort( function( a, b ){
			return a.title > b.title ? 1 : -1;
		} );

		return list;
	}

	/**
	 * Returns an array of context IDs that are valid for the given parent contexts
	 * @autodoc
	 * @parentContext.hint IDs of the parent contexts
	 */
	public array function listValidExpressionContextsForParentContexts( required array parentContexts ) {
		var contexts      = _getConfiguredContexts();
		var validContexts = Duplicate( arguments.parentContexts );

		for( var parentContext in arguments.parentContexts ) {
			var subContexts   = contexts[ parentContext ].subcontexts ?: [];
			for( var subContext in subContexts ) {
				validContexts.append( listValidExpressionContextsForParentContexts( [ subContext ] ), true );
			}
		}

		return validContexts;
	}

	/**
	 * Returns an array of context IDs expanded from a source array of contexts to include
	 * any parent contexts
	 *
	 * @autodoc
	 * @contexts.hint IDs of the contexts to expand
	 */
	public array function expandContexts( required array contexts ) {
		var configuredContexts = _getConfiguredContexts();
		var expanded = Duplicate( arguments.contexts );

		for( var sourceContext in arguments.contexts ) {
			for ( var contextName in configuredContexts ) {
				var subContexts = configuredContexts[ contextName ].subcontexts ?: [];

				if ( subContexts.findNoCase( sourceContext ) && !expanded.findNoCase( contextName ) ) {
					expanded.append(  expandContexts( [ contextName ] ), true );
				}
			}
		}

		return expanded;
	}

	/**
	 * Returns the configured object (if any) for the given context
	 *
	 * @autodoc true
	 * @context.hint ID of the context whose configured object you wish to get
	 */
	public string function getContextObject( required string context ) {
		var contexts = _getConfiguredContexts();

		return contexts[ arguments.context ].object ?: "";
	}

	/**
	 * Returns an array of context ids for the given object
	 *
	 * @autodoc true
	 * @objectName.hint Object whose contexts you wish to get
	 */
	public array function getObjectContexts( required string objectName ) {
		var contexts = _getConfiguredContexts();
		var objectContexts = [];

		for( var contextId in contexts ) {
			if ( getContextObject( contextId ) == arguments.objectName ) {
				objectContexts.append( contextId );
			}
		}

		return expandContexts( objectContexts );
	}

	/**
	 * Dynamically registers a new context with the given
	 * ID. Any extra arguments are added to the context
	 * definition.
	 *
	 * @autodoc true
	 * @id.hint ID of the context
	 */
	public void function addContext( required string id ) {
		var contexts    = _getConfiguredContexts();
		var contextArgs = Duplicate( arguments );

		contextArgs.delete( "id" );
		contexts[ arguments.id ] = contextArgs;
	}

	/**
	 * Returns the payload for the given context and optional
	 * set of args to the payload's context getting handler.
	 *
	 * @autodoc true
	 * @context.hint ID of the context whose payload we are to get
	 * @args.hint    Optional set of args to send to the context getPayload() handler
	 */
	public struct function getContextPayload( required string context, struct args={} ) {
		var coldboxController = $getColdbox();
		var expanded          = listValidExpressionContextsForParentContexts( [ arguments.context ] );
		var payload           = {};

		for( var cx in expanded ) {
			var handlerAction = "rules.contexts.#cx#.getPayload";

			if ( coldboxController.handlerExists( handlerAction ) ) {
				payload.append( $getColdbox().runEvent(
					  event          = handlerAction
					, eventArguments = arguments.args
					, private        = true
					, prePostExempt  = true
				) );
			}
		}

		return payload;
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredContexts() {
		return _configuredContexts;
	}
	private void function _setConfiguredContexts( required struct configuredContexts ) {
		_configuredContexts = arguments.configuredContexts;
	}

}