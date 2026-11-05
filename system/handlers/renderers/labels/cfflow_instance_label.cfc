/**
 * @feature cfflow
 */
component {

	private array function _selectFields( event, rc, prc ) {
		return [ "reference", "owner" ];
	}

	private string function _renderLabel( required string reference, required string owner ) {
		var title = translateResource( uri="webflow.#arguments.reference#:title", defaultValue=arguments.reference );
		var owner = renderContent( "webflowOwner", arguments.owner );

		return EncodeForHtml( title ) & ": " & EncodeForHtml( owner );
	}

}