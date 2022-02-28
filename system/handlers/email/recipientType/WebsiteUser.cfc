/**
 * Handler for website user interactions
 *
 */
component {
	property name="websiteUserDao" inject="presidecms:object:website_user";

	private struct function prepareParameters( event, rc, prc, args={}, recipientId="" ) {
		var user = websiteUserDao.selectData( id=arguments.recipientId );

		for( var u in user ) {
			u.form_name = arguments.args.form_name ?: "";

			return u;
		}

		u = {};
		for( var col in ListToArray( user.columnList ) ) {
			u[ col ] = "";
		}

		u.form_name = arguments.args.form_name ?: "";

		return u;
	}

	private struct function getPreviewParameters( event, rc, prc, args={} ) {
		return {
			  display_name  = "Sam Montoya"
			, login_id      = "sam"
			, email_address = "sam.montoya@test.com"
			, form_name     = "Contact us"
		};
	}

	private string function getToAddress( required string recipientId ) {
		var user = websiteUserDao.selectData( id=arguments.recipientId );

		return user.email_address ?: "";
	}
}