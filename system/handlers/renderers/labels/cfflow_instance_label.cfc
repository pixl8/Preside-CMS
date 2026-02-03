/**
 * @feature cfflow
 */
component {

	private array function _selectFields( event, rc, prc ) {
		return [ "reference", "owner" ];
	}

	private string function _renderLabel( required string reference, required string owner ) {
		return translateResource( uri="webflow.#arguments.reference#:title", defaultValue=arguments.reference ) & ": #renderContent( "webflowOwner", arguments.owner )#";
	}

}