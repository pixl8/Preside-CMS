/**
 * Handler for the user rules engine context
 *
 */
component {

	private struct function getPayload() {
		var payload = { website_user = getLoggedInUserDetails() };

		payload.user = payload.website_user; // backward compat

		return payload;
	}

}