/**
 * Handler for the admin user rules engine context
 *
 */
component {

	private struct function getPayload( event, rc, prc ) {
		var payload = { security_user = event.getAdminUserDetails() };

		return payload;
	}

}