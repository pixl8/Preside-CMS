/**
 * Handler for the page rules engine context
 *
 */
component {

	private struct function getPayload() {
		return { page = ( prc.presidePage ?: {} ) };
	}

}