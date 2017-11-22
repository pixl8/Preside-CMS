component extends="preside.system.base.AdminHandler" {

	property name="adHocTaskManagerService" inject="adHocTaskManagerService";

	public void function preHandler( event ) {
		super.preHandler( argumentCollection=arguments );
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:adhoctaskmanager.breadcrumb.title" )
			, link  = ""
		);
		prc.pageIcon     = "hourglass-2";
	}

// PUBLIC HANDLERS
	public void function progress( event, rc, prc ) {
		var taskId = rc.taskId ?: "";

		prc.task = adHocTaskManagerService.getTask( taskId );

		if ( !prc.task.admin_owner.len() || prc.task.admin_owner != event.getAdminUserId() ) {
			_checkPermissions( event, "viewtask" );
		}

		var taskTitleData = IsJson( prc.task.title_data ?: "" ) ? DeserializeJson( prc.task.title_data ) : [];
		var taskTitle = translateResource( uri=prc.task.title, data=taskTitleData, defaultValue=prc.task.title );

		prc.pageTitle    = translateResource( uri="cms:adhoctaskmanager.progress.page.title", data=[ taskTitle ] );
		prc.pageSubtitle = translateResource( uri="cms:adhoctaskmanager.progress.page.subtitle", data=[ taskTitle ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:adhoctaskmanager.progress.breadcrumb.title", data=[ taskTitle ] )
			, link  = ""
		);
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