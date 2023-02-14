/**
 * Handler for the user rules engine context
 *
 */
component {

	property name="emailSendingContextService" inject="emailSendingContextService";

	private struct function getPayload() {
		var emailPayload = emailSendingContextService.getContextPayload();

		if ( StructKeyExists( emailPayload, "website_user" ) ) {
			emailPayload.user = emailPayload.website_user; // backward compat
			return emailPayload;
		}

		var payload = { website_user = getLoggedInUserDetails() };
		payload.user = payload.website_user; // backward compat

		return payload;
	}

}