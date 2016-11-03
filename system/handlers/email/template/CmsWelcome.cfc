component {

	private struct function prepareParameters(
		  required string welcomeMessage
		, required string createdBy
		, required string resetToken
	) {
		return {
			  welcomeMessage    = { text=arguments.welcomeMessage ?: "", html=renderView( view="/email/template/cmsWelcome/_welcomeMessage", args=arguments ) }
			, createdBy         = ( arguments.createdBy   ?: "" )
			, siteUrl           = event.getSite().domain
			, resetPasswordLink = event.buildAdminLink(
				  linkto      = "login.resetpassword"
				, querystring = "token=" & ( arguments.resetToken ?: "" )
			  )
		};
	}

	private string function defaultSubject() {
		return "Welcome to PresideCMS";
	}

	private string function defaultHtmlBody() {
		return renderView( view="/email/template/cmsWelcome/defaultHtmlBody" );
	}

	private string function defaultTextBody() {
		return renderView( view="/email/template/cmsWelcome/defaultTextBody" );
	}


}