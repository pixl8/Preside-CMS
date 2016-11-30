/**
 * Core tasks for the task manager
 *
 */
component {

	property name="emailMassSendingService" inject="emailMassSendingService";

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
}