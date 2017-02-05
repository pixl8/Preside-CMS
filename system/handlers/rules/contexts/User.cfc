/**
 * Handler for the user rules engine context
 *
 */
component {

	property name="emailSendingContextService" inject="emailSendingContextService";

	private struct function getPayload() {
		var emailPayload = emailSendingContextService.getContextPayload();

		if ( emailPayload.keyExists( "website_user" ) ) {
			return emailPayload;
		}

		var payload = { website_user = getLoggedInUserDetails() };
		payload.user = payload.website_user; // backward compat

		return payload;
	}

}