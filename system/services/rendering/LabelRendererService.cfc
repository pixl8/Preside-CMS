/**
 * @presideservice
 * @singleton
 *
 */
component {

// CONSTRUCTOR
	public any function init() {
		_setLabelRendererCache( {} );

		return this;
	}

// PUBLIC API METHODS
	public array function getSelectFieldsForLabel( required string labelRenderer, boolean includeAlias=true ) {
		var selectFieldsHandler = _getSelectFieldsHandler( labelRenderer );
		var selectFields        = [];

		if ( len( labelRenderer ) && $getColdbox().handlerExists( selectFieldsHandler ) ) {
			selectFields = $getColdbox().runEvent(
				  event          = selectFieldsHandler
				, prePostExempt  = true
				, private        = true
			);
		} else {
			selectFields = [ "${labelfield} as label" ];
		}

		if ( !arguments.includeAlias ) {
			selectFields = selectFields.map( function( item, index, arr ){
				return trim( reReplaceNoCase( item, "\s+as\s+?.*$", "" ) );
			} );
		}

		return selectFields;
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
			return args.label ?: "";
		}
	}

	public string function getRendererCacheDate( required string labelRenderer ) {
		var rendererExists = len( labelRenderer ) && $getColdbox().handlerExists( _getSelectFieldsHandler( labelRenderer ) );

		if ( rendererExists ) {
			var cache  = _getLabelRendererCache();
			if ( !StructKeyExists( cache, labelRenderer ) ) {
				cache[ labelRenderer ] = now();
			}

			return cache[ labelRenderer ];
		}

		return createDateTime( 1970, 1, 1, 0, 0, 0 );
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


	private struct function _getLabelRendererCache() {
		return _labelRendererCache;
	}
	private void function _setLabelRendererCache( required struct labelRendererCache ) {
		_labelRendererCache = arguments.labelRendererCache;
	}

}