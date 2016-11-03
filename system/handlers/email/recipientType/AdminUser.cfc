/**
 * Handler for admin user interactions
 *
 */
component {
	property name="adminUserDao" inject="presidecms:object:security_user";

	private struct function prepareParameters( event, rc, prc, args={} ) {
		var user = adminUserDao.selectData( id=args.userId ?: "" );

		for( var u in user ) {
			return u;
		}

		return {};
	}

	private string function getToAddress( event, rc, prc, args={} ) {
		var user = adminUserDao.selectData( id=args.userId ?: "" );

		return user.email_address ?: "";
	}
}