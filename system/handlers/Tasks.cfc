/**
 * Core tasks for the task manager
 *
 * @feature taskManager
 */
component {

	property name="emailLoggingService"     inject="emailLoggingService";
	property name="notificationService"     inject="notificationService";
	property name="workflowService"         inject="WorkflowService";
	property name="websiteLoginService"     inject="featureInjector:websiteUsers:websiteLoginService";
	property name="adhocTaskManagerService" inject="adhocTaskManagerService";
	property name="assetQueueService"       inject="assetQueueService";
	property name="batchOperationService"   inject="dataManagerBatchOperationService";
	property name="formBuilderService"      inject="formBuilderService";

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
	 * Delete expired batch operation queues
	 *
	 * @schedule     0 41 3 * * *
	 * @displayName  Delete expired batch operation queues
	 * @displayGroup Cleanup
	 */
	private boolean function deleteExpiredBatchOperationQueues( logger ) {
		return batchOperationService.deleteExpiredOperationQueues( arguments.logger ?: NullValue() );
	}


	/**
	 * Delete expired derivative generation queues
	 *
	 * @priority     5
	 * @schedule     0 0 7 * * *
	 * @timeout      1200
	 * @displayName  Cleanup asset generation queue
	 * @displayGroup Cleanup
	 * @feature      assetQueue
	 */
	private boolean function deleteExpiredQueuedAssetGenerations( logger ) {
		return assetQueueService.deleteExpiredQueuedItems( arguments.logger ?: NullValue() );
	}

	/**
	 * Delete expired form builder submissions
	 *
	 * @priority     10
	 * @schedule     0 14 4 * * *
	 * @timeout      1200
	 * @displayName  Delete expired form builder submissions
	 * @displayGroup Cleanup
	 * @feature      formbuilder
	 */
	private boolean function deleteExpiredFormBuilderSubmissions( logger ) {
		return formBuilderService.deleteExpiredSubmissions( arguments.logger ?: NullValue() );
	}
}