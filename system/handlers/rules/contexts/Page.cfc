/**
 * Handler for the page rules engine context
 *
 * @feature rulesEngine and sitetree
 */
component {

	private struct function getPayload() {
		return { page = ( prc.presidePage ?: {} ) };
	}

}