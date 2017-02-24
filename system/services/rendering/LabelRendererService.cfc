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
	public boolean function rendererExistsFor( required string objectName ) {
		var selectFieldsHandler = _getSelectFieldsHandler( objectName );
		var renderLabelHandler  = _getRenderLabelHandler( objectName );

		return $getColdbox().handlerExists( selectFieldsHandler ) && $getColdbox().handlerExists( renderLabelHandler );
	}

	public array function getSelectFieldsForLabel( required string objectName ) {
		var selectFieldsHandler = _getSelectFieldsHandler( objectName );

		if ( $getColdbox().handlerExists( selectFieldsHandler ) ) {
			return $getColdbox().runEvent(
				  event          = selectFieldsHandler
				, prePostExempt  = true
				, private        = true
			);
		} else {
			return [ "${labelfield} as label" ];
		}
	}

	public string function renderLabel( required string objectName, struct args={} ) {
		var renderLabelHandler   = _getRenderLabelHandler( objectName );
		
		if ( $getColdbox().handlerExists( renderLabelHandler ) ) {
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

// PRIVATE HELPERS
	private string function _getSelectFieldsHandler( required string objectName ) {
		return "renderers.labels.#objectName#._selectFields";
	}

	private string function _getRenderLabelHandler( required string objectName ) {
		return "renderers.labels.#objectName#._renderLabel";
	}

}