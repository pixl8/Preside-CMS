/**
 * @presideservice
 * @singleton
 *
 */
component {

// CONSTRUCTOR

	/**
	 * @coldbox.inject              coldbox
	 * @presideObjectService.inject PresideObjectService
	 */
	public any function init( required any coldbox, required any presideObjectService ) {
		_setColdbox( arguments.coldbox );
		_setPresideObjectService( arguments.presideObjectService );

		return this;
	}

// PUBLIC API METHODS
	public array function getSelectFieldsForLabel( required string objectName ) {
		var selectFieldsHandler = "renderers.labels.#objectName#.selectFields";

		if ( _getColdbox().handlerExists( selectFieldsHandler ) ) {
			return _getColdbox().runEvent(
				  event          = selectFieldsHandler
				, prePostExempt  = true
			);
		} else {
			return [ "${labelfield} as label" ];
		}
	}

	public string function renderLabel( required string objectName, struct args={} ) {
		var renderLabelHandler = "renderers.labels.#objectName#.renderLabel";

		if ( _getColdbox().handlerExists( renderLabelHandler ) ) {
			return _getColdbox().runEvent(
				  event          = renderLabelHandler
				, prePostExempt  = true
				, eventArguments = args
			);
		} else {
			return args.label ?: "";
		}
	}

// PRIVATE HELPERS
	

// GETTERS AND SETTERS
	private any function _getColdbox() {
		return _coldbox;
	}
	private void function _setColdbox( required any coldbox ) {
		_coldbox = arguments.coldbox;
	}

	private any function _getPresideObjectService() {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) {
		_presideObjectService = arguments.presideObjectService;
	}
}