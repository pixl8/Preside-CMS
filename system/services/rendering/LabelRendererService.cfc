/**
 * @presideservice
 * @singleton
 *
 */
component {

// CONSTRUCTOR

	public any function init() {
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

	public string function getGroupByForLabels( required string labelRenderer, struct args={} ) {
		var groupByHandler = _getGroupByHandler( labelRenderer );

		if ( len( labelRenderer ) && $getColdbox().handlerExists( groupByHandler ) ) {
			return $getColdbox().runEvent(
				  event          = groupByHandler
				, prePostExempt  = true
				, private        = true
			);
		} else {
			return "";
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

// PRIVATE HELPERS
	private string function _getSelectFieldsHandler( required string labelRenderer ) {
		return "renderers.labels.#labelRenderer#._selectFields";
	}

	private string function _getGroupByHandler( required string labelRenderer ) {
		return "renderers.labels.#labelRenderer#._groupBy";
	}

	private string function _getOrderByHandler( required string labelRenderer ) {
		return "renderers.labels.#labelRenderer#._orderBy";
	}

	private string function _getRenderLabelHandler( required string labelRenderer ) {
		return "renderers.labels.#labelRenderer#._renderLabel";
	}

}