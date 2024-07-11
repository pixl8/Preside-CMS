/**
 * @feature admin and adhocTasks
 */
component extends="preside.system.base.AdminHandler" {

	property name="adHocTaskManagerService" inject="adHocTaskManagerService";
	property name="taskManagerService"      inject="taskManagerService";
	property name="logRendererUtil"         inject="logRendererUtil";

	public void function preHandler( event ) {
		super.preHandler( argumentCollection=arguments );

		var taskId          = rc.taskId ?: "";
		var resultUrl       = event.buildAdminLink();
		var hideBreadCrumbs = isTrue( rc.hideBreadCrumbs ?: "" );

		if ( len( trim( taskId ) ) ) {
			var task  = adHocTaskManagerService.getTask( taskId );
			resultUrl = task.return_url.len() ? task.return_url : event.buildAdminLink();
		}
		if( !hideBreadCrumbs ){
			event.addAdminBreadCrumb(
					title = translateResource( "cms:adhoctaskmanager.breadcrumb.title" )
				, link  = resultUrl
			);
		}

		prc.pageIcon     = "hourglass-2";
	}

// PUBLIC HANDLERS
	public void function progress( event, rc, prc ) {
		var taskId = rc.taskId ?: "";

		prc.task = adHocTaskManagerService.getTask( taskId );
		if ( !prc.task.recordCount ) {
			event.notFound();
		}

		if ( !prc.task.admin_owner.len() || prc.task.admin_owner != event.getAdminUserId() ) {
			_checkPermissions( event, "viewtask" );
		}

		if ( prc.task.status == "succeeded" && prc.task.result_url.len() ) {
			setNextEvent( url=prc.task.result_url );
		}

		var taskTitleData = IsJson( prc.task.title_data ?: "" ) ? DeserializeJson( prc.task.title_data ) : [];
		var taskTitle = translateResource( uri=prc.task.title, data=taskTitleData, defaultValue=prc.task.title );

		prc.taskProgress = adHocTaskManagerService.getProgress( taskId );

		if ( prc.task.status == "pending" ) {
			prc.taskProgress.timeTaken = translateResource( "enum.adhocTaskStatus:pending.title" );
			prc.taskProgress.log       = logRendererUtil.renderLegacyLogs( translateResource( "cms:adhoctaskmanager.progress.pending.log" ) );
			prc.taskProgress.lineCount = 0;
		} else {
			if ( Len( prc.taskProgress.log ) ) {
				prc.taskProgress.lineCount = ListLen( prc.taskProgress.log, Chr( 10 ) );
				prc.taskProgress.log       = logRendererUtil.renderLegacyLogs( prc.taskProgress.log );
			} else {
				prc.taskProgress.lineCount = adhocTaskManagerService.getLogLineCount( prc.taskProgress.id );
				prc.taskProgress.log       = logRendererUtil.renderLogs( adhocTaskManagerService.getLogLines( prc.taskProgress.id ) );
			}
			prc.taskProgress.timeTaken = renderContent( renderer="TaskTimeTaken", data=prc.taskProgress.timeTaken*1000, context=[ "accurate" ] );
		}

		if ( isTrue( prc.task.disable_cancel ?: "" ) ) {
			prc.canCancel = false;
		} else {
			prc.canCancel = prc.task.status == "running" || prc.task.status == "pending";
			prc.canCancel = prc.canCancel && ( prc.task.admin_owner == event.getAdminUserId() || hasCmsPermission( "adhocTaskManager.canceltask" ) );
		}
		
		prc.pageTitle    = translateResource( uri="cms:adhoctaskmanager.progress.page.title", data=[ taskTitle ] );
		prc.pageSubtitle = translateResource( uri="cms:adhoctaskmanager.progress.page.subtitle", data=[ taskTitle ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:adhoctaskmanager.progress.breadcrumb.title", data=[ taskTitle ] )
			, link  = ""
		);
	}

	public void function status( event, rc, prc ) {
		var taskId       = rc.taskId ?: "";
		var task         = adHocTaskManagerService.getTask( taskId );
		var taskProgress = adHocTaskManagerService.getProgress( taskId );
		var fetchAfter   = Val( rc.fetchAfterLines ?: "" );

		if ( !task.admin_owner.len() || task.admin_owner != event.getAdminUserId() ) {
			_checkPermissions( event, "viewtask" );
		}

		taskProgress.logLineCount = adhocTaskManagerService.getLogLineCount( taskId );
		taskProgress.log          = logRendererUtil.renderLogs( adhocTaskManagerService.getLogLines( taskId, fetchAfter ), fetchAfter );

		if ( task.status == "pending" ) {
			taskProgress.timeTaken = translateResource( "enum.adhocTaskStatus:pending.title" );
		} else {
			taskProgress.timeTaken = renderContent( renderer="TaskTimeTaken", data=taskProgress.timeTaken*1000, context=[ "accurate" ] );
		}


		event.renderData(
			  data = taskProgress
			, type = "json"
		);
	}

	public void function cancelTaskAction( event, rc, prc ) {
		var taskId       = rc.taskId ?: "";
		var task         = adHocTaskManagerService.getTask( taskId );
		var taskProgress = adHocTaskManagerService.getProgress( taskId );
		var resultUrl    = task.return_url.len() ? task.return_url : event.buildAdminLink();

		if ( isTrue ( task.disable_cancel ?: "" ) ) {
			event.adminAccessDenied();
		}

		if ( !task.admin_owner.len() || task.admin_owner != event.getAdminUserId() ) {
			_checkPermissions( event, "canceltask" );
		}

		adhocTaskManagerService.cancelTask( taskId );
		setNextEvent( url=resultUrl );
	}

// PRIVATE HELPERS
	private boolean function _checkPermissions( required any event, required string key, boolean throwOnError=true ) {
		var hasPermission = hasCmsPermission( "adhocTaskManager." & arguments.key );
		if ( !hasPermission && arguments.throwOnError ) {
			event.adminAccessDenied();
		}

		return hasPermission;
	}
}