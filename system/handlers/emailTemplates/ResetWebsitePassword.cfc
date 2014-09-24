component output=false {

	private struct function prepareMessage( event, rc, prc, args={} ) output=false {

		var resetLink = event.buildLink(
			  linkto      = "login.resetpassword"
			, querystring = "token=" & ( args.resetToken ?: "" )
		);

		return {
			  subject  = "Password reset instructions"
			, textBody = resetLink
		};
	}

}