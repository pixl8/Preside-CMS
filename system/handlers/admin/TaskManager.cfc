component extends="preside.system.base.AdminHandler" {

	property name="taskManagerService"         inject="taskManagerService";
	property name="taskHistoryDao"             inject="presidecms:object:taskmanager_task_history";
	property name="systemConfigurationService" inject="systemConfigurationService";
	property name="messageBox"                 inject="messagebox@cbmessagebox";
	property name="cookieStorage"              inject="cookieStorage@cbstorages";

	public void function preHandler( event ) {
		super.preHandler( argumentCollection=arguments );
		_checkPermission( "navigate", event );

		prc.pageIcon     = "clock-o";
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:taskmanager.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="taskmanager" )
		);
	}

	public void function index( event, rc, prc ) {
		prc.activeTaskGroup    = 1;
		prc.taskGroups         = taskManagerService.getAllTaskDetails();
		prc.autoRunningEnabled = systemConfigurationService.getSetting( "taskmanager", "scheduledtasks_enabled", false );

		if ( len( rc.tab ?: "" ) ) {
			cookieStorage.setVar( "_presideTaskManagerTab", rc.tab );
		}
		var tab = cookieStorage.getVar( "_presideTaskManagerTab", "" );
		if ( len( tab ) ) {
			prc.taskGroups.each( function( group, index, array ){
				if ( group.slug == tab ) {
					prc.activeTaskGroup = index;
					break;
				}
			} );
		}

		prc.pageTitle    = translateResource( "cms:taskmanager.page.title"    );
		prc.pageSubTitle = translateResource( "cms:taskmanager.page.subtitle" );
	}

	public void function configure( event, rc, prc ) output=false {
		_checkPermission( "configure", event );

		prc.configuration = systemConfigurationService.getCategorySettings( "taskmanager" );

		prc.pageTitle    = translateResource( "cms:taskmanager.configure.page.title"    );
		prc.pageSubTitle = translateResource( "cms:taskmanager.configure.page.subtitle" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:taskmanager.configureTask.page.title" )
			, link  = event.buildAdminLink( linkTo="taskmanager.configure" )
		);
	}

	public void function configureTask( event, rc, prc ) {
		_checkPermission( "configure", event );

		var task       = rc.task ?: "";
		var taskDetail = taskManagerService.getTask( task );

		prc.taskConfiguration = taskManagerService.getTaskConfiguration( task );
		prc.pageTitle         = translateResource( "cms:taskmanager.configureTask.page.title" );
		prc.pageSubTitle      = taskDetail.name;

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:taskmanager.configure.page.crumbtrail", data=[ taskDetail.name ] )
			, link  = event.buildAdminLink( linkTo="taskmanager.configureTask", queryString="task=" & task )
		);
	}

	public void function saveConfigurationAction( event, rc, prc ) {
		_checkPermission( "configure", event );

		var formData = event.getCollectionForForm( "taskmanager.configuration" );

		for( var setting in formData ){
			systemConfigurationService.saveSetting(
				  category = "taskmanager"
				, setting  = setting
				, value    = formData[ setting ]
			);
		}

		event.audit(
			  action = "edit_taskmanager_configuration"
			, type   = "taskmanager"
			, detail = formData
		);

		messageBox.info( translateResource( uri="cms:taskmanager.configuration.saved" ) );

		setNextEvent( url=event.buildAdminLink( linkTo="taskmanager" ) );

	}

	public void function saveTaskConfigurationAction( event, rc, prc ) {
		_checkPermission( "configure", event );

		var task             = rc.task ?: "";
		var formName         = "taskmanager.task_configuration";
		var formData         = event.getCollectionForForm( formName );
		var validationResult = validateForm( formName, formData );
		var crontabError     = taskManagerService.getValidationErrorMessageForPotentiallyBadCrontabExpression( formData.crontab_definition ?: "" );

		if ( Len( Trim( crontabError ) ) ) {
			validationResult.addError( fieldName="crontab_definition", message=crontabError );
		}

		if ( !validationResult.validated() ) {
			var persist = formData;
			    persist.validationResult = validationResult;

			setNextEvent(
				  url           = event.buildAdminLink( linkTo="taskmanager.configureTask", queryString="task=" & task )
				, persistStruct = persist
			);
		}

		taskManagerService.saveTaskConfiguration(
			  taskKey = task
			, config  = formData
		);

		event.audit(
			  action   = "edit_taskmanager_task_configuration"
			, type     = "taskmanager"
			, recordId = task
			, detail   = formData
		);

		messageBox.info( translateResource( uri="cms:taskmanager.configuration.saved" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="taskmanager" ) );
	}

	public void function runTaskAction( event, rc, prc ) {
		_checkPermission( "run", event );

		var task = rc.task ?: "";

		taskManagerService.runTask( task );
		event.audit(
			  action   = "taskmanager_run_task"
			, type     = "taskmanager"
			, recordId = task
		);

		sleep( 200 );
		var historyId = taskManagerService.getActiveHistoryIdForTask( task );

		setNextEvent( url=event.buildAdminLink( linkTo="taskManager.viewLog", querystring="id=" & historyId ) );
	}

	public void function killRunningTaskAction( event, rc, prc ) {
		_checkPermission( "run", event );

		taskManagerService.killRunningTask( rc.task ?: "" );
		event.audit(
			  action   = "taskmanager_kill_task"
			, type     = "taskmanager"
			, recordId = task
		);

		setNextEvent( url=event.buildAdminLink( "taskManager" ) );
	}

	public void function enableTaskAction( event, rc, prc ) {
		_checkPermission( "toggleactive", event );
		taskManagerService.enableTask( rc.task ?: "" );
		event.audit(
			  action   = "taskmanager_enable_task"
			, type     = "taskmanager"
			, recordId = rc.task ?: ""
		);

		setNextEvent( url=event.buildAdminLink( "taskManager" ) );
	}

	public void function disableTaskAction( event, rc, prc ) {
		_checkPermission( "toggleactive", event );
		taskManagerService.disableTask( rc.task ?: "" );
		event.audit(
			  action   = "taskmanager_disable_task"
			, type     = "taskmanager"
			, recordId = rc.task ?: ""
		);

		setNextEvent( url=event.buildAdminLink( "taskManager" ) );
	}

	public void function  history( event, rc, prc ) {
		_checkPermission( "viewlogs", event );

		prc.task         = taskmanagerService.getTask( rc.task ?: "" );

		prc.pageTitle    = translateResource( uri="cms:taskmanager.history.page.title", data=[ prc.task.name ] );
		prc.pageSubTitle = translateResource( uri="cms:taskmanager.history.page.subtitle" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:taskmanager.history.breadcrumb", data=[ prc.task.name ] )
			, link  = event.buildAdminLink( linkTo="taskmanager.history" )
		);

		prc.history = taskHistoryDao.selectData(
			  selectFields = [ "id", "datecreated", "success", "time_taken", "complete", "log" ]
			, orderBy      = "datecreated desc"
			, filter       = { task_key = task }
			, maxRows      = 50
		);
	}

	public void function viewLog( event, rc, prc ) {
		_checkPermission( "viewlogs", event );

		var log = taskHistoryDao.selectData(
			  id           = rc.id ?: "---"
			, selectFields = [ "task_key", "success", "time_taken", "complete", "log", "datecreated" ]
			, useCache     = false
		);

		if ( !log.recordCount ) {
			setNextEvent( url=event.buildAdminLink( linkTo="taskmanager" ) );
		}
		for( var l in log ) { prc.log = l; }
		prc.log.log = taskManagerService.createLogHtml( prc.log.log );

		prc.log.time_taken = IsTrue( prc.log.complete ) ? prc.log.time_taken : DateDiff( 's', prc.log.datecreated, Now() ) * 1000;
		prc.log.time_taken = renderContent( renderer="TaskTimeTaken", data=prc.log.time_taken, context=[ "accurate" ] );

		prc.task = taskmanagerService.getTask( log.task_key );
		prc.pageTitle    = translateResource( uri="cms:taskmanager.log.page.title", data=[ prc.task.name, DateTimeFormat( log.datecreated, "dd MMM yyyy 'at' HH:nn:ss" ) ] );
		prc.pageSubTitle = translateResource( uri="cms:taskmanager.log.page.subtitle", data=[ prc.task.name, DateTimeFormat( log.datecreated, "dd MMM yyyy 'at' HH:nn:ss" ) ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:taskmanager.history.breadcrumb", data=[ prc.task.name ] )
			, link  = event.buildAdminLink( linkTo="taskmanager.history", queryString="task=#log.task_key#" )
		);

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:taskmanager.log.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="taskManager.viewLog", queryString="id=#rc.id#" )
		);

		if ( !prc.log.complete ) {
			event.includeData({
				  logUpdateUrl = event.buildAdminLink( linkTo="taskmanager.ajaxLogUpdate", queryString="id=" & rc.id )
				, lineCount    = ListLen( prc.log.log, Chr( 10 ) )
			});
		}

	}

	public void function ajaxLogUpdate( event, rc, prc ) {
		_checkPermission( "viewlogs", event );

		var log = taskHistoryDao.selectData(
			  id           = rc.id ?: "---"
			, selectFields = [ "task_key", "success", "time_taken", "complete", "log", "datecreated" ]
			, useCache     = false
		);
		if ( !log.recordCount ) {
			event.notFound();
		}
		for( var l in log ) { log = l; break; }
		log.lineCount = ListLen( log.log, Chr(10) );
		log.log = taskManagerService.createLogHtml( log.log, Val( rc.fetchAfterLines ?: "" ) );

		log.time_taken = IsTrue( log.complete ) ? log.time_taken : DateDiff( 's', log.datecreated, Now() ) * 1000;
		log.time_taken = renderContent( renderer="TaskTimeTaken", data=log.time_taken, context=[ "accurate" ] );

		event.renderData( data=log, type="json" );
	}



// private helpers
	private void function _checkPermission( required string permissionKey, required any event ) {
		if ( !hasCmsPermission( "taskmanager." & arguments.permissionKey ) ) {
			event.adminAccessDenied();
		}
	}
}