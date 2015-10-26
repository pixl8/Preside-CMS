/**
 * Email template scaffolded by the PresideCMS scaffolding service.
 * See https://docs.presidecms.com/devguides/emailtemplating.html for a full guide
 * on email templating.
 *
 */
component {

	private struct function prepareMessage( event, rc, prc, args={} ) {
		// TODO, any business logic here to prepare message
		// arguments (expected arguments below)

		var message = {
			  subject  = args.subject ?: ""
			, to       = args.to ?: [] // should be an array of email addresses
			, from     = getSystemSetting( "email", "default_from_address", "" )
			, textBody = args.textBody ?: ""
			, htmlBody = args.htmlBody ?: ""
			, params   = args.params   ?: {}
		};

		return message;
	}

}