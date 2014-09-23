component output=false {

	private struct function index( event, rc, prc, args={} ) output=false {

		var resetLink = event.buildLink(
			  linkto      = "login.resetpassword"
			, querystring = "token=" & ( args.resetToken ?: "" )
		);

		return {
			  subject       = "PresideCMS: Password reset instructions"
			, plainTextBody = resetLink
			, from          = "test@test.com"
		};
	}

}