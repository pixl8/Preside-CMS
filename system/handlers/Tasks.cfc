/**
 * Core tasks for the task manager
 *
 */
component {

	property name="emailMassSendingService" inject="emailMassSendingService";
	property name="emailLoggingService"     inject="emailLoggingService";

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
	 * Delete expired saved email content from the logs
	 *
	 * @priority     5
	 * @schedule     0 0 3 * * *
	 * @timeout      1200
	 * @displayName  Delete expired email content
	 * @displayGroup Email
	 */
	private boolean function deleteExpiredEmailContent( logger ) {
		return emailLoggingService.deleteExpiredContent( arguments.logger ?: NullValue() );
	}
}