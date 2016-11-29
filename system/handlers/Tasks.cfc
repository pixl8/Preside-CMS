/**
 * Core tasks for the task manager
 *
 */
component {

	property name="emailMassSendingService" inject="emailMassSendingService";

	/**
	 * Sends out any queued batch emails.
	 *
	 * @priority     5
	 * @schedule     0 *\/2 * * * *
	 * @timeout      1200
	 * @displayName  Send queued batch email
	 * @displayGroup Email
	 */
	private boolean function sendQueuedEmails( logger ) {
		return emailMassSendingService.processQueue( arguments.logger ?: NullValue() );
	}
}