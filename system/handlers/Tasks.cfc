/**
 * Core tasks for the task manager
 *
 */
component {

	property name="emailLoggingService"     inject="emailLoggingService";
	property name="notificationService"     inject="notificationService";
	property name="workflowService"         inject="WorkflowService";
	property name="websiteLoginService"     inject="websiteLoginService";
	property name="adhocTaskManagerService" inject="adhocTaskManagerService";
	property name="assetQueueService"       inject="assetQueueService";

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
	 * Delete expired workflows
	 *
	 * @priority     5
	 * @schedule     0 0 3 * * *
	 * @timeout      1200
	 * @displayName  Delete expired workflows
	 * @displayGroup Cleanup
	 */
	private boolean function deleteExpiredWorkflows( logger ) {
		return workflowService.deleteExpiredWorkflows( arguments.logger ?: NullValue() );
	}

	/**
	 * Delete expired password reset tokens
	 *
	 * @priority     5
	 * @schedule     0 0 3 * * *
	 * @displayName  Delete expired password reset tokens
	 * @displayGroup Cleanup
	 * @feature      websiteUsers
	 */
	private boolean function deleteExpiredPasswordResetTokens( logger ) {
		return websiteLoginService.deleteExpiredPasswordResetTokens( arguments.logger ?: NullValue() );
	}

	/**
	 * Delete expired ad-hoc tasks
	 *
	 * @priority     5
	 * @schedule     0 0 3 * * *
	 * @timeout      1200
	 * @displayName  Delete expired ad-hoc tasks
	 * @displayGroup Cleanup
	 */
	private boolean function deleteExpiredAdhocTasks( logger ) {
		return adhocTaskManagerService.deleteExpiredAdhocTasks( arguments.logger ?: NullValue() );
	}

	/**
	 * Delete expired derivative generation queues
	 *
	 * @priority     5
	 * @schedule     0 0 7 * * *
	 * @timeout      1200
	 * @displayName  Cleanup asset generation queue
	 * @displayGroup Cleanup
	 */
	private boolean function deleteExpiredQueuedAssetGenerations( logger ) {
		return assetQueueService.deleteExpiredQueuedItems( arguments.logger ?: NullValue() );
	}
}