# Task Manager: Scheduled & Ad-hoc Background Tasks

## Scheduled Tasks

Define scheduled tasks as private functions in `/handlers/Tasks.cfc` (or `/handlers/ScheduledTasks.cfc`).

```cfml
// /handlers/Tasks.cfc
component {

    property name="searchService" inject="searchService";

    /**
     * @displayName      Rebuild search indexes
     * @displayGroup     search
     * @schedule         0 *\/15 * * * *
     * @priority         10
     * @exclusivityGroup search
     * @timeout          300
     */
    private boolean function rebuildSearchIndexes( event, rc, prc, logger ) {
        logger.info( "Starting rebuild..." );

        try {
            searchService.rebuildAll( logger=arguments.logger );
            logger.info( "Rebuild complete." );
            return true;
        } catch( any e ) {
            logger.error( "Rebuild failed: #e.message#" );
            return false;
        }
    }

    /**
     * @displayName   Clean up tmp files
     * @displayGroup  maintenance
     * @schedule      0 0 2 * * *
     */
    private boolean function cleanTmpFiles( event, rc, prc, logger ) {
        logger.info( "Cleaning tmp files older than 24 hours" );
        fileService.cleanTmp( maxAgeInHours=24 );
        return true;
    }
}
```

### 6-Point Cron Schedule Format

```
S  M  H  DoM  Mon  DoW
0  0  *   *    *    *   = Every hour at :00
0  */15 * *    *    *   = Every 15 minutes
0  30  2  *    *    2   = 2:30 AM every Tuesday
0  0   4  1    *    *   = 4 AM on the 1st of each month
```

Fields: Second (0-59), Minute (0-59), Hour (0-23), Day of Month (1-31), Month (1-12), Day of Week (1-7, 1=Monday)

### Task Annotations

| Annotation | Description |
|------------|-------------|
| `@displayName` | Human-readable name shown in admin UI |
| `@displayGroup` | Tab grouping in admin task manager UI |
| `@schedule` | 6-point cron expression |
| `@priority` | Order in exclusivity group (lower = higher priority) |
| `@exclusivityGroup` | Tasks in same group won't run concurrently |
| `@timeout` | Max execution time in seconds (informational only as of v10.10.0) |

### Logger Methods

The `logger` argument supports:
```cfml
logger.info( "Informational message" )
logger.warn( "Warning message" )
logger.error( "Error message" )
logger.fatal( "Fatal message" )
```

### Check for Interruption

```cfml
private boolean function longRunningTask( event, rc, prc, logger ) {
    do {
        if ( $isInterrupted() ) {
            logger.warn( "Task interrupted, stopping gracefully" );
            return false;
        }
        _processNextBatch();
    } while( _hasMoreBatches() );
    return true;
}
```

### Run a Scheduled Task Programmatically

```cfml
// In services (PresideSuperClass):
$runTask( taskKey="rebuildSearchIndexes" );
$runTask( taskKey="rebuildSearchIndexes", args={ index="products" } );

// Via service:
property name="taskManagerService" inject="taskManagerService";
taskManagerService.runTask( "rebuildSearchIndexes" );
```

---

## Ad-hoc Background Tasks (v10.9.0+)

For long-running operations triggered by user actions (imports, exports, etc.).

### Create a Task

```cfml
// In any handler or service:
var taskId = createTask(
      event    = "admin.blog.exportPostsInBackground"  // Handler event path
    , args     = { format="csv", filter={ published=true } }
    , runNow   = true
);

// With delay:
createTask(
      event  = "cleanup.oldFiles"
    , args   = { maxAgeDays=7 }
    , runIn  = CreateTimeSpan( 0, 0, 5, 0 )  // Run in 5 minutes
);

// With retry logic:
createTask(
      event         = "integration.syncToExternalApi"
    , args          = { recordIds=selectedIds }
    , runNow        = true
    , retryInterval = [
          { tries=2, interval=CreateTimeSpan( 0, 0, 5,  0 ) }   // 5 min × 2
        , { tries=2, interval=CreateTimeSpan( 0, 0, 30, 0 ) }   // 30 min × 2
        , { tries=1, interval=CreateTimeSpan( 0, 1, 0,  0 ) }   // 1 hour × 1
      ]
);
```

### Task Handler

```cfml
// /handlers/admin/Blog.cfc
component extends="preside.system.base.AdminHandler" {

    // Handler that creates the task and redirects to progress UI
    public void function exportPosts( event, rc, prc ) {
        var taskId = createTask(
              event      = "admin.blog.exportPostsInBackground"
            , args       = { format=rc.format ?: "csv" }
            , runNow     = true
            , adminOwner = event.getAdminUserId()
            , title      = "cms:blog.export.task.title"
            , resultUrl  = event.buildAdminLink(
                  linkTo      = "blog.downloadExport"
                , queryString = "taskId={taskId}"
              )
            , returnUrl  = event.buildAdminLink( linkTo="blog.index" )
        );

        setNextEvent( url=event.buildAdminLink(
              linkTo      = "adhoctaskmanager.progress"
            , queryString = "taskId=" & taskId
        ) );
    }

    // The actual background work
    private void function exportPostsInBackground(
          event, rc, prc
        , args     = {}
        , logger         // For logging progress messages
        , progress       // For reporting % complete
    ) {
        var format  = args.format ?: "csv";
        var posts   = blogService.getAllForExport();
        var total   = posts.recordCount;
        var done    = 0;

        var filePath = getTempFile( getTempDirectory(), "BlogExport" );
        var writer   = csvService.createWriter( filePath );

        for ( var post in posts ) {
            if ( progress.isCancelled() ) {
                writer.close();
                FileDelete( filePath );
                abort;
            }

            writer.writeRow( [ post.title, post.author, post.datecreated ] );
            done++;

            if ( !(done mod 50) || done == total ) {
                progress.setProgress( Int( (done/total) * 100 ) );
                logger.info( "Exported #done# of #total# posts" );
            }
        }

        writer.close();

        // Store result for download handler
        progress.setResult({ filePath=filePath, format=format });
    }

    // Download handler reads task result
    public void function downloadExport( event, rc, prc ) {
        property name="adhocTaskManagerService" inject="adhocTaskManagerService";

        var task     = adhocTaskManagerService.getProgress( rc.taskId ?: "" );
        var filePath = task.result.filePath ?: "";

        if ( !FileExists(filePath) ) { event.notFound(); }

        header name="Content-Disposition" value='attachment; filename="export.csv"';
        content reset=true file=filePath type="text/csv" deletefile=true;
        adhocTaskManagerService.discardTask( rc.taskId );
        abort;
    }
}
```

### Progress Object Methods

```cfml
progress.setProgress( 50 )          // 0-100 integer
progress.isCancelled()              // boolean — user hit Cancel
progress.setResult( { key=value } ) // Store arbitrary result data
```

### AdHocTaskManagerService Methods

```cfml
property name="adhocTaskManagerService" inject="adhocTaskManagerService";

adhocTaskManagerService.getProgress( taskId )    // struct with progress, result, status
adhocTaskManagerService.discardTask( taskId )    // Clean up after completion
adhocTaskManagerService.cancelTask( taskId )     // Request cancellation
```

### createTask() Options

| Option | Description |
|--------|-------------|
| `event` | Handler event path (required) |
| `args` | Struct passed to handler as `args` |
| `runNow` | Boolean — run immediately |
| `runIn` | TimeSpan — delay before running |
| `runAt` | DateTime — specific scheduled time |
| `retryInterval` | Array of `{tries, interval}` retry structs |
| `adminOwner` | Admin user ID for ownership tracking |
| `title` | i18n key or text for admin UI display |
| `resultUrl` | URL to redirect to after completion (`{taskId}` substituted) |
| `returnUrl` | URL for Cancel/Back button |
