component {

	private struct function prepareParameters( required string resetToken ) {
		return {
			  site_url            = event.getSite().domain
			, reset_password_link = event.buildAdminLink(
				  linkto      = "login.resetpassword"
				, querystring = "token=" & ( arguments.resetToken ?: "" )
			  )
		};
	}

	private struct function getPreviewParameters() {
		return {
			  site_url            = event.getSite().domain
			, reset_password_link = event.getSite().protocol & "://" & event.getSite().domain & "/dummy/reset/passwordlink/"
		};
	}

	private string function defaultSubject() {
		return "Reset your PresideCMS password";
	}

	private string function defaultHtmlBody() {
		return renderView( view="/email/template/resetCmsPassword/defaultHtmlBody" );
	}

	private string function defaultTextBody() {
		return renderView( view="/email/template/resetCmsPassword/defaultTextBody" );
	}
}