component output=false {

	private struct function prepareMessage( event, rc, prc, args={} ) output=false {

		args.resetLink = event.buildAdminLink(
			  linkto      = "login.resetpassword"
			, querystring = "token=" & ( args.resetToken ?: "" )
		);
		args.websiteName  = args.websiteName ?: event.getSite().domain;
		args.emailAddress = args.to[1]       ?: "";
		args.userName     = args.userName    ?: "";

		return {
			  subject  = "Password reset instructions"
			, textBody = renderView( view="/emailTemplates/resetCmsPassword/text", args=args )
			, htmlBody = renderView( view="/emailTemplates/resetCmsPassword/html", args=args )
		};
	}

}