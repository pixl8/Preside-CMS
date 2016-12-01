/**
 * Handler for admin user interactions
 *
 */
component {
	property name="adminUserDao" inject="presidecms:object:security_user";

	private struct function prepareParameters( event, rc, prc, args={}, recipientId="" ) {
		var user = adminUserDao.selectData( id=arguments.recipientId );

		for( var u in user ) {
			return u;
		}

		u = {};
		for( var col in ListToArray( user.columnList ) ) {
			u[ col ] = "";
		}
		return u;
	}

	private struct function getPreviewParameters( event, rc, prc, args={} ) {
		return {
			  known_as      = "Jane Smith"
			, login_id      = "jane"
			, email_address = "jane.smith@test.com"
		};
	}

	private string function getToAddress( required string recipientId ) {
		var user = adminUserDao.selectData( id=arguments.recipientId );

		return user.email_address ?: "";
	}
}