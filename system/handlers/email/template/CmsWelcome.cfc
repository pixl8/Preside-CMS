component {

	private struct function prepareParameters(
		  required string welcomeMessage
		, required string createdBy
		, required string resetToken
	) {
		return {
			  welcome_message     = { text=arguments.welcomeMessage ?: "", html=renderView( view="/email/template/cmsWelcome/_welcomeMessage", args=arguments ) }
			, created_by          = ( arguments.createdBy   ?: "" )
			, site_url            = event.getBaseUrl()
			, reset_password_link = event.buildAdminLink(
				  linkto      = "login.resetpassword"
				, querystring = "token=" & ( arguments.resetToken ?: "" )
			  )
		};
	}

	private struct function getPreviewParameters() {
		var welcomeMessage = "Hey Jane, welcome to the CMS - I'll help you get setup after lunch :)";

		return {
			  welcome_message     = { text=welcomeMessage, html=renderView( view="/email/template/cmsWelcome/_welcomeMessage", args={ welcomeMessage=welcomeMessage } ) }
			, created_by          = "Mia Thornstone"
			, site_url            = event.getBaseUrl()
			, reset_password_link = event.getBaseUrl() & "/dummy/reset/passwordlink/"
		};
	}

	private string function defaultSubject() {
		return "Welcome to Preside";
	}

	private string function defaultHtmlBody() {
		return renderView( view="/email/template/cmsWelcome/defaultHtmlBody" );
	}

	private string function defaultTextBody() {
		return renderView( view="/email/template/cmsWelcome/defaultTextBody" );
	}


}