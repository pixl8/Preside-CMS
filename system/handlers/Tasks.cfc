/**
 * Core tasks for the task manager
 *
 */
component {

	property name="emailMassSendingService" inject="emailMassSendingService";
	property name="websiteLoginService"     inject="websiteLoginService";

	/**
	 * Process batched emails
	 *
	 * @priority     5
	 * @schedule     0 *\/2 * * * *
	 * @timeout      1200
	 * @displayName  Process batch email
	 * @displayGroup Email
	 */
	private boolean function processBatchedEmails( logger ) {
		return emailMassSendingService.processQueue( arguments.logger ?: NullValue() );
	}

	/**
	 * Resend email to expired token website users
	 *
	 * @priority     5
	 * @schedule     0 *\/10 * * * *
	 * @timeout      1200
	 * @displayName  Resend email to expired token website users
	 * @displayGroup Email
	 */
	private boolean function resendToken( logger ) {
		return websiteLoginService.resendToken( arguments.logger ?: NullValue() );
	}
}