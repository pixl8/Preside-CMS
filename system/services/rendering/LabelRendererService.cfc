/**
 * @presideservice
 * @singleton
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @labelRendererCache.inject  cachebox:LabelRendererCache
	 *
	 */
	public any function init( required any labelRendererCache ) {
		_setLabelRendererCache( arguments.labelRendererCache );

		return this;
	}

// PUBLIC API METHODS
	public array function getSelectFieldsForLabel( required string labelRenderer ) {
		var selectFieldsHandler = _getSelectFieldsHandler( labelRenderer );

		if ( len( labelRenderer ) && $getColdbox().handlerExists( selectFieldsHandler ) ) {
			return $getColdbox().runEvent(
				  event          = selectFieldsHandler
				, prePostExempt  = true
				, private        = true
			);
		} else {
			return [ "${labelfield} as label" ];
		}
	}

	public string function getOrderByForLabels( required string labelRenderer, struct args={} ) {
		var orderByHandler = _getOrderByHandler( labelRenderer );

		if ( len( labelRenderer ) && $getColdbox().handlerExists( orderByHandler ) ) {
			return $getColdbox().runEvent(
				  event          = orderByHandler
				, prePostExempt  = true
				, private        = true
			);
		} else {
			return args.orderBy;
		}
	}

	public string function renderLabel( required string labelRenderer, struct args={} ) {
		var renderLabelHandler   = _getRenderLabelHandler( labelRenderer );
		
		if ( len( labelRenderer ) && $getColdbox().handlerExists( renderLabelHandler ) ) {
			return $getColdbox().runEvent(
				  event          = renderLabelHandler
				, prePostExempt  = true
				, private        = true
				, eventArguments = args
			);
		} else {
			return HTMLEditFormat( args.label ?: "" );
		}
	}

	public string function getRendererCacheDate( required string labelRenderer ) {
		var cacheDate      = createDateTime( 1970, 1, 1, 0, 0, 0 );
		var cache          = _getLabelRendererCache();
		var rendererExists = len( labelRenderer ) && $getColdbox().handlerExists( _getSelectFieldsHandler( labelRenderer ) );

		if ( rendererExists ) {
			var cached = cache.get( labelRenderer );

			if ( !IsNull( cached ) ) {
				cacheDate = cached;
			} else {
				cacheDate = now();
				cache.set( labelRenderer, cacheDate );
			}
		}

		return cacheDate;
	}

// PRIVATE HELPERS
	private string function _getSelectFieldsHandler( required string labelRenderer ) {
		return "renderers.labels.#labelRenderer#._selectFields";
	}

	private string function _getOrderByHandler( required string labelRenderer ) {
		return "renderers.labels.#labelRenderer#._orderBy";
	}

	private string function _getRenderLabelHandler( required string labelRenderer ) {
		return "renderers.labels.#labelRenderer#._renderLabel";
	}


	private any function _getLabelRendererCache() {
		return _labelRendererCache;
	}
	private void function _setLabelRendererCache( required any labelRendererCache ) {
		_labelRendererCache = arguments.labelRendererCache;
	}

}