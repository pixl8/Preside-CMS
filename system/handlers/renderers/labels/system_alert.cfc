/**
 * @feature admin
 */
component {

	private array function _selectFields( event, rc, prc ) {
		return [ "type" ];
	}

	private string function _renderLabel( type="" ) {
		return translateResource( uri="systemAlerts.#type#:title", defaultValue=type );
	}

}