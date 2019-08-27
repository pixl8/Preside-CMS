component {

	property name="loginService" inject="loginService";
	property name="sendLogDao"   inject="presidecms:object:email_template_send_log";

	private struct function prepareParameters( required string resetToken ) {
		return {
			  site_url            = event.getBaseUrl()
			, reset_password_link = event.buildAdminLink(
				  linkto      = "login.resetpassword"
				, querystring = "token=" & ( arguments.resetToken ?: "" )
			  )
		};
	}

	private struct function getPreviewParameters() {
		return {
			  site_url            = event.getBaseUrl()
			, reset_password_link = event.getBaseUrl() & "/dummy/reset/passwordlink/"
		};
	}

	private string function defaultSubject() {
		return "Reset your Preside password";
	}

	private string function defaultHtmlBody() {
		return renderView( view="/email/template/resetCmsPassword/defaultHtmlBody" );
	}

	private string function defaultTextBody() {
		return renderView( view="/email/template/resetCmsPassword/defaultTextBody" );
	}

	private struct function rebuildArgsForResend( required string logId ) {
		var userId    = sendLogDao.selectData( id=logId, selectFields=[ "security_user_recipient" ] ).security_user_recipient;
		var tokenInfo = loginService.createLoginResetToken( userId );

		return { resetToken="#tokenInfo.resetToken#-#tokenInfo.resetKey#" };
	}
}