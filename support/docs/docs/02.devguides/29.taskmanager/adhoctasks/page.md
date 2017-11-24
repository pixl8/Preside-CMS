---
id: taskmanager-adhoctasks
title: Task manager - ad-hoc tasks (10.9.0 and above)
---

As of v10.9.0, PresideCMS allows you to create, run and optionally track, ad-hoc background tasks. For example, the core data export and form builder export functionality now runs in the background and uses a core Preside admin view to track and deliver the final download.

For predefined scheduled tasks, see [[taskmanager-predefinedtasks]].

![Screenshot of ad-hoc task live progress view](images/screenshots/adhoc-task.jpg)

## Creating and running a task

The [[adhoctaskmanagerservice-createtask]] method of the [[api-adhoctaskmanagerservice]] service will register a task and optionally allow you to run it. 

>>> To make life easier, this method can be directly accessed in your handlers with just `createTask()`, or in your service objects with [[presidesuperclass-$createtask]]

Example usage:

```luceescript
// a fictional example, run the `Cleanup.cfc$tmpFiles` handler
// as a background task
createTask(
	  event  = "cleanup.tmpfiles"
	, args   = { maxAgeInDays=2 }
	, runNow = true
);
```

## Reporting task progress

The handler event that you use in the [[adhoctaskmanagerservice-createtask]] method receives three extra arguments from the system:

1. `args`: struct of args passed to the [[adhoctaskmanagerservice-createtask]]  method
2. `logger`: a logger object with which you can log progress. The logger uses the same interface as all LogBox loggers.
3. `progress`: a progress object with which you can report progress and set a result for your task (see [[api-adhoctaskprogressreporter]])

Use the `logger` and `progress` objects to log messages against the task, track level of completion and set a final result. Usage example:

```luceescript
// /application/handlers/Cleanup.cfc
component {

	private void function tmpFiles( event, rc, prc, args={}, logger, progress ) {
		var maxAgeInDays  = Val( args.maxAgeInDays ?: 1 )
		var filesToDelete = _getTmpFilesToDelete( maxAgeInDays );
		var totalFiles    = filesToDelete.len();
		var filesDeleted  = 0;

		for( var file in filesToDelete ) {
			FileDelete( file );
			filesDeleted++;

			// log at every 100 files to save DB bandwidth...
			if ( !filesDeleted mod 100 || filesDeleted == totalFiles ) {
				if ( progress.isCancelled() ) {
					abort;
				}

				progress.setProgress( 100 / totalFiles * filesDeleted );
				logger.info( "Deleted [#NumberFormat( filesDeleted )#] out of [#NumberFormat( totalFiles )#] tmp files" );
			}
		}

		progress.setResult( { success=true, filecount=filesDeleted } );
	}
}
```

>>> Notice the `progress.isCancelled()` call. You can optionally use this to abort execution of the task early, making any necessary cleanup code that you may need to execute.

## Delayed execution

You can delay execution of a task with the `runIn` argument. The `runIn` argument must be a `TimeSpan` object and can not be used in conjunction with `runNow=true`. For example:

```luceescript
// Set to run in 5 minutes time from now
createTask(
	  event  = "cleanup.tmpfiles"
	, args   = { maxAgeInDays=2 }
	, runIn  = CreateTimeSpan( 0, 0, 5, 0 )
);
```

## Automatically retrying failures

If your task fails, i.e. throws an error, you can optionally configure it to retry execution to a schedule using the `retryInterval` argument. This argument can either be a single struct, or an array of structs with the following form:

```luceescript
{
	  tries    = 3
	, interval = CreateTimeSpan( 0, 0, 5, 0 ) 
}
```

The `tries` key describes the number of attempts to make. The `interval` key describes the time to wait between attempts. For example:

```luceescript
// Retry failures after 5 minutes, 20 minutes, 1 hour and finally, 1 day
createTask(
	  event  = "cleanup.tmpfiles"
	, args   = { maxAgeInDays=2 }
	, runNow = true
	, retryInterval = [
		  { tries=1, CreateTimeSpan( 0, 0, 5 , 0) } // retry once after 5m
		, { tries=1, CreateTimeSpan( 0, 0, 20, 0) } // retry once after 20m
		, { tries=3, CreateTimeSpan( 0, 1, 0 , 0) } // retry three x after 1h
		, { tries=1, CreateTimeSpan( 1, 0, 0 , 0) } // retry once after 1d
	  ]
);
```

## Progress tracking UI for admin users

For tasks that require some action on completion and/or monitoring by the admin user that instigated them, you can hook into core admin handlers to follow progress. The following example illustrates the full cycle of this using the form builder export feature as an example:

```luceescript
// inject 'adhocTaskManagerService', required for getting task progress
// in result handler
property name="adhocTaskManagerService" inject="adhocTaskManagerService";

// user instigated 'export submissions' action
public void function exportSubmissions( event, rc, prc ) {
	var formId   = rc.formId ?: "";
	var theForm  = formBuilderService.getForm( formId );

	if ( !theForm.recordCount ) {
		event.adminNotFound();
	}

	// create task and get its ID
	var taskId = createTask(
		  event      = "admin.formbuilder.exportSubmissionsInBackgroundThread"
		, args       = { formId=formId }
		, runNow     = true
		, adminOwner = event.getAdminUserId()
		, title      = "cms:formbuilder.export.task.title"
		, resultUrl  = event.buildAdminLink( linkto="formbuilder.downloadExport", querystring="taskId={taskId}" )
		, returnUrl  = event.buildAdminLink( linkto="formbuilder.manageForm", querystring="id=" & formId )
	);

	// redirect to core 'adhoctaskmanager.progress' page with Task ID
	// this page shows progress bar and redirects to 'resultURL' on success
	setNextEvent( url=event.buildAdminLink(
		  linkTo      = "adhoctaskmanager.progress"
		, queryString = "taskId=" & taskId
	) );
}

// handler action that will perform the ad-hoc task in the background
private void function exportSubmissionsInBackgroundThread( event, rc, prc, args={}, logger, progress ) {
	var formId = args.formId ?: "";

	// here, the formBuilderService takes care of tracking
	// progress with the logger + progress objects
	formBuilderService.exportResponsesToExcel(
		  formId      = formId
		, writeToFile = true
		, logger      = arguments.logger   ?: NullValue()
		, progress    = arguments.progress ?: NullValue()
	);
}

// "result" URL, user automatically redirected here at end of progress
// because defined in "resultUrl" in "CreateTask" method
public void function downloadExport( event, rc, prc ) {
	var taskId          = rc.taskId ?: "";
	var task            = adhocTaskManagerService.getProgress( taskId );
	var localExportFile = task.result.filePath       ?: "";
	var exportFileName  = task.result.exportFileName ?: "";
	var mimetype        = task.result.mimetype       ?: "";

	if ( task.isEmpty() || !localExportFile.len() || !FileExists( localExportFile ) ) {
		event.notFound();
	}

	header name="Content-Disposition" value="attachment; filename=""#exportFileName#""";
	content reset=true file=localExportFile deletefile=true type=mimetype;

	adhocTaskManagerService.discardTask( taskId );
	abort;

}
```