component {

	property name="websiteLoginService" inject="websiteLoginService";
	property name="sendLogDao"          inject="presidecms:object:email_template_send_log";
	property name="userDao"             inject="presidecms:object:website_user";

	private struct function prepareParameters(
		required string resetToken
	) {
		return {
			  site_url            = event.getSite().domain
			, reset_password_link = event.buildLink(
				  page        = "reset_password"
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
		return "Password reset instructions";
	}

	private string function defaultHtmlBody() {
		return renderView( view="/email/template/resetWebsitePasswordForTokenExpiry/defaultHtmlBody" );
	}

	private string function defaultTextBody() {
		return renderView( view="/email/template/resetWebsitePasswordForTokenExpiry/defaultTextBody" );
	}

	private struct function rebuildArgsForResend( required string logId ) {
		var userId    = sendLogDao.selectData( id=logId, selectFields=[ "website_user_recipient" ] ).website_user_recipient;
		var tokenInfo = websiteLoginService.createPasswordResetToken();

		userDao.updateData( id=userId, data={
			  reset_password_token        = tokenInfo.resetToken
			, reset_password_key          = tokenInfo.hashedResetKey
			, reset_password_token_expiry = tokenInfo.resetTokenExpiry
		} );

		return { resetToken="#tokenInfo.resetToken#-#tokenInfo.resetKey#" };
	}

}