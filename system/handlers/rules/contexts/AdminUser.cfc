/**
 * Handler for the admin user rules engine context
 *
 * @feature rulesEngine and admin
 */
component {

	private struct function getPayload( event, rc, prc ) {
		var payload = { security_user = event.getAdminUserDetails() };

		return payload;
	}

}