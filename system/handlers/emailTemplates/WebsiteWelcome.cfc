component output=false {

	private struct function prepareMessage( event, rc, prc, args={} ) output=false {

		args.resetLink = event.buildLink(
			  page        = "reset_password"
			, querystring = "token=" & ( args.resetToken ?: "" )
		);
		args.websiteName  = args.websiteName ?: event.getSite().domain;
		args.emailAddress = args.to[1]       ?: "";
		args.userName     = args.userName    ?: "";

		return {
			  subject  = "Welcome to the website"
			, textBody = renderView( view="/emailTemplates/websiteWelcome/text", args=args )
			, htmlBody = renderView( view="/emailTemplates/websiteWelcome/html", args=args )
		};
	}

}