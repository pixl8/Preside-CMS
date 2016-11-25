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

	private string function getToAddress( event, rc, prc, args={} ) {
		var user = adminUserDao.selectData( id=args.userId ?: "" );

		return user.email_address ?: "";
	}

	private string function getRecipientId( event, rc, prc, args={} ) {
		return args.userId ?: "";
	}
}