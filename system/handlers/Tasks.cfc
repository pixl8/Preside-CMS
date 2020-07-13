/**
 * Core tasks for the task manager
 *
 */
component {

	property name="emailLoggingService"     inject="emailLoggingService";
	property name="notificationService"     inject="notificationService";
	property name="websiteLoginService"     inject="websiteLoginService";

	/**
	 * Delete expired saved email content from the logs
	 *
	 * @priority     5
	 * @schedule     0 0 3 * * *
	 * @timeout      1200
	 * @displayName  Delete expired email content
	 * @displayGroup Cleanup
	 * @feature      emailCenterResend
	 */
	private boolean function deleteExpiredEmailContent( logger ) {
		return emailLoggingService.deleteExpiredContent( arguments.logger ?: NullValue() );
	}

	/**
	 * Delete old notifications
	 *
	 * @priority     5
	 * @schedule     0 0 3 * * *
	 * @timeout      1200
	 * @displayName  Delete old notifications
	 * @displayGroup Cleanup
	 */
	private boolean function deleteOldNotifications( logger ) {
		return notificationService.deleteOldNotifications( arguments.logger ?: NullValue() );
	}

	/**
	 * Delete expired password reset tokens
	 *
	 * @priority     5
	 * @schedule     0 0 3 * * *
	 * @timeout      1200
	 * @displayName  Delete expired password reset tokens
	 * @displayGroup Cleanup
	 * @feature      websiteUsers
	 */
	private boolean function deleteExpiredPasswordResetTokens( logger ) {
		return websiteLoginService.deleteExpiredPasswordResetTokens( arguments.logger ?: NullValue() );
	}

}