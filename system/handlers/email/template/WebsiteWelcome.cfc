/**
 * @feature websiteUsers
 */
component {

	private struct function prepareParameters(
		required string resetToken
	) {
		return {
			  site_url            = event.getSiteUrl( includeProtocol=false )
			, reset_password_link = event.buildLink(
				  page        = "reset_password"
				, querystring = "token=" & ( arguments.resetToken ?: "" )
			  )
		};
	}

	private struct function getPreviewParameters() {
		return {
			  site_url            = event.getSiteUrl( includeProtocol=false )
			, reset_password_link = event.getSiteUrl() & "/dummy/reset/passwordlink/"
		};
	}

	private string function defaultSubject() {
		return "Welcome to the website";
	}

	private string function defaultHtmlBody() {
		return renderView( view="/email/template/websiteWelcome/defaultHtmlBody" );
	}

	private string function defaultTextBody() {
		return renderView( view="/email/template/websiteWelcome/defaultTextBody" );
	}


}