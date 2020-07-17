/**
 * @singleton      true
 * @presideService true
 */
component {
	/**
	 * @scheduledReportDao.inject           presidecms:object:scheduled_report_export
	 * @scheduledReportHistoryDao.inject    presidecms:object:scheduled_report_export_history
	 * @threadUtil.inject                   threadUtil
	 */
	public any function init(
		  required any scheduledReportDao
		, required any scheduledReportHistoryDao
		, required any threadUtil
	) {
		_setScheduledReportDao(        arguments.scheduledReportDao        );
		_setScheduledReportHistoryDao( arguments.scheduledReportHistoryDao );
		_setThreadUtil(                arguments.threadUtil                );

		_setMachineId();
		_setRunningExports({});

		return this;
	}

	public string function getHistoryExportFile( required string historyExportId ) {
		var file = _getScheduledReportHistoryDao().selectData( id=arguments.historyExportId, selectFields=[ "filepath" ] );

		if ( file.recordcount ) {
			return file.filepath ?: "";
		}

		return "";
	}

	public void function saveFilePathToHistoryExport( required string filepath, required string historyExportId ) {
		try {
			_getScheduledReportHistoryDao().updateData( id=arguments.historyExportId, data={ filepath=arguments.filepath } );
		} catch (any e) {
			$raiseError(e);
		}
	}

	public void function sendExportedReportToRecipient( required string historyExportId ) {
		try {
			var detail          = getHistoryReportDetail( arguments.historyExportId );
			var scheduledReport = detail.scheduled_report ?: "";
			var reportFilepath  = detail.filepath         ?: ""

			if ( !isEmpty( scheduledReport ) and !isEmpty( reportFilepath ) ) {
				var recipients = valueArray( _getScheduledReportDao().selectManyToManyData(
					  id           = scheduledReport
					, propertyName = "recipients"
					, selectFields = [ "recipients.id" ]
				), "id" ) ?: [];

				for ( var recipient in recipients ) {
					$sendEmail(
						  template    = "scheduledReportExport"
						, recipientId = recipient
						, args        = { filepath=reportFilepath }
					);
				}
			}
		} catch (any e) {
			$raiseError(e);
		}
	}

	public struct function getReportDetail( required string reportId ) {
		var detail = _getScheduledReportDao().selectData( id=arguments.reportId );

		return !isEmpty( detail ) ? queryGetRow( detail, 1 ) : {};
	}

	public struct function getHistoryReportDetail( required string historyReportId ) {
		var detail = _getScheduledReportHistoryDao().selectData( id=arguments.historyReportId );

		return !isEmpty( detail ) ? queryGetRow( detail, 1 ) : {};
	}

	public void function saveScheduledReport( required struct data ) {
		try {
			arguments.data.is_running = false;

			if ( !isEmpty( arguments.data.schedule ?: "" ) ) {
				arguments.data.next_run = getNextRunDate( arguments.data.schedule );
			}

			_getScheduledReportDao().insertData( data=arguments.data, insertManyToManyRecords=true );
		} catch (any e) {
			$raiseError( e );
		}
	}

	public void function updateScheduleReport( required string recordId, required string schedule ) {
		try {
			_getScheduledReportDao().updateData( id=arguments.recordId, data={ next_run=getNextRunDate( arguments.schedule ) } );
		} catch (any e) {
			$raiseError( e );
		}
	}

	public string function getNextRunDate( required string schedule, date lastRun=now() ) {
		var cronTabExpression = _getCrontabExpressionObject( arguments.schedule );
		var lastRunJodaTime   = _createJodaTimeObject( arguments.lastRun );

		return cronTabExpression.nextTimeAfter( lastRunJodaTime  ).toDate();
	}

	public string function cronExpressionToHuman( required string expression ) {
		if ( arguments.expression == "disabled" ) {
			return "disabled";
		}
		return CreateObject( "java", "net.redhogs.cronparser.CronExpressionDescriptor", _getLib() ).getDescription( arguments.expression );
	}

	public void function sendScheduledReports() {
		var nonRunningReports = _getScheduledReportDao().selectData(
			  selectFields = [ "id" ]
			, filter       = "is_running = :is_running and next_run < :next_run"
			, filterParams = { is_running = false, next_run = now() }
			, useCache     = false
		);

		for ( var report in nonRunningReports ) {
			runReportExport( report.id );
		}
	}

	public void function runReportExport( required string scheduledReportId ) {
		var reportDetail = getReportDetail( arguments.scheduledReportId )
		var lockName     = "runexport-#arguments.scheduledReportId#";

		try {
			lock name=lockName type="exclusive" timeout=1 {
				var newThreadId = "PresideReportScheduledExport-" & arguments.scheduledReportId & "-" & CreateUUId();
				var newLogId    = createReportExportHistoryLog( arguments.scheduledReportId, newThreadId );

				transaction {
					if ( exportIsRunning( arguments.scheduledReportId ) ) {
						return;
					}

					markReportExportAsRunning( arguments.scheduledReportId, newThreadId );
				}

				markReportExportAsStarted( arguments.scheduledReportId );
				runReportExportWithinThread(
					  scheduledReportId = arguments.scheduledReportId
					, historyLogId      = newLogId
					, threadId          = newThreadId
				);
			}
		} catch (any e) {
			$raiseError(e);
		}
	}

	public void function runReportExportWithinThread(
		  required string scheduledReportId
		, required string historyLogId
		, required string threadId
	) {
		var start           = getTickCount();
		var success         = false;
		var tu              = _getThreadUtil();

		try {
			$getRequestContext().setUseQueryCache( false );

			success = $getColdbox().runEvent(
				  event          = "ScheduledReportHelpers.runScheduledReportExport"
				, private        = true
				, eventArguments = { args={ scheduledReportId=scheduledReportId, historyExportId=historyLogId } }
			);
		} catch (any e) {
			$raiseError(e);
		} finally {
			markReportExportAsCompleted( arguments.historyLogId, arguments.scheduledReportId, success, getTickCount() - start );
		}
	}

	public numeric function markReportExportAsRunning(
		  required string reportId
		, required string threadId
	) {
		var reportDetail   = getReportDetail( arguments.reportId )
		var runningExports = _getRunningExports();

		runningExports[ arguments.threadId ] = { status="queued", thread=NullValue() };

		return _getScheduledReportDao().updateData(
			  id   = arguments.reportId
			, data = {
				  is_running      = true
				, next_run        = getNextRunDate( reportDetail.schedule )
				, running_thread  = arguments.threadId
				, running_machine = _getMachineId()
			  }
		);
	}

	public void function markReportExportAsStarted( required string threadId ) {
		var runningExports = _getRunningExports();

		runningExports[ arguments.threadId ] = { status="started" };
	}

	public numeric function markReportExportAsCompleted(
		  required string  historyReportId
		, required string  reportId
		, required boolean success
		, required numeric timeTaken
	) {
		completeReportExportHistoryLog(
			  historyExportId = arguments.historyReportId
			, success         = arguments.success
			, timeTaken       = arguments.timeTaken
		);

		var runningTasks = _getRunningExports();
		var reportRecord = getReportDetail( arguments.reportId );

		runningTasks.delete( reportRecord.running_thread ?: "", false );

		var updatedRows = _getScheduledReportDao().updateData(
			  id   = arguments.reportId
			, data = {
				  is_running           = false
				, last_ran             = now()
				, next_run             = getNextRunDate( reportRecord.schedule ?: "" )
				, was_last_run_success = arguments.success
				, last_run_time_taken  = arguments.timeTaken
				, running_thread       = ""
				, running_machine      = ""
			  }
		);

		return updatedRows;
	}

	public string function createReportExportHistoryLog(
		  required string reportId
		, required string threadId
	) {
		return _getScheduledReportHistoryDao().insertData( data={
			  scheduled_report = arguments.reportId
			, thread_id        = arguments.threadId
			, machine_id       = _getMachineId()
		} );
	}

	public numeric function completeReportExportHistoryLog(
		  required string  historyExportId
		, required boolean success
		, required numeric timeTaken
	) {
		return _getScheduledReportHistoryDao().updateData(
			  id   = arguments.historyExportId
			, data = {
				  complete   = true
				, success    = arguments.success
				, time_taken = arguments.timeTaken
			}
		);
	}

	public boolean function exportIsRunning( required string reportId ) {
		transaction {
			var markedAsRunning = _getScheduledReportDao().dataExists( filter = { id=arguments.reportId, is_running=true } );

			if ( markedAsRunning && !taskThreadIsRunning( arguments.taskKey ) ) {
				var logger = _getLogger( taskKey=arguments.taskKey );

				if ( logger.canError() ) {
					logger.error( "Task was marked as running but task thread is no longer running." );
				}

				markTaskAsCompleted(
					  taskKey   = arguments.taskKey
					, success   = false
					, timetaken = -1
				);
				return false;
			}

			return markedAsRunning;
		}
	}

	public boolean function exportThreadIsRunning( required string reportId ) {
		var report = _getScheduledReportDao().selectData(
			  selectFields = [ "running_thread", "running_machine" ]
			, id           = arguments.reportId
		);

		if ( !report.recordCount || !Len( Trim( report.running_thread ?: "" ) ) ) {
			return false;
		}

		if ( report.running_machine != _getMachineId() ) {
			return true;
		}

		return _exportIsRunningOnLocalMachine( report );
	}

// PRIVATE HELPERS
	private array function _getLib() {
		return [
			  "/preside/system/services/taskmanager/lib/cron-parser-2.6-SNAPSHOT.jar"
			, "/preside/system/services/taskmanager/lib/commons-lang3-3.3.2.jar"
			, "/preside/system/services/taskmanager/lib/joda-time-2.9.4.jar"
			, "/preside/system/services/taskmanager/lib/cron-1.0.jar"
		];
	}

	private any function _createJodaTimeObject( required date cfmlDateTime ) {
		return CreateObject( "java", "org.joda.time.DateTime", _getLib() ).init( cfmlDateTime );
	}

	private any function _getCrontabExpressionObject( required string expression ) {
		return CreateObject( "java", "fc.cron.CronExpression", _getLib() ).init( arguments.expression );
	}

	private boolean function _exportIsRunningOnLocalMachine( required any task ){
		var runningTasks = _getRunningTasks();
		var threadRef    = runningTasks[ task.running_thread ].thread ?: NullValue();

		if ( IsNull( threadRef ) ) {
			return false;
		}
		try {
			return !threadRef.isDone() && !threadRef.isCancelled();
		} catch( any e ) {
			$raiseError( e );
		}

		return false;
	}

// GETTERS AND SETTERS
	private any function _getScheduledReportDao() {
		return _scheduledReportDao;
	}
	private void function _setScheduledReportDao( required any scheduledReportDao ) {
		_scheduledReportDao = arguments.scheduledReportDao;
	}

	private any function _getScheduledReportHistoryDao() {
		return _scheduledReportHistoryDao;
	}
	private void function _setScheduledReportHistoryDao( required any scheduledReportHistoryDao ) {
		_scheduledReportHistoryDao = arguments.scheduledReportHistoryDao;
	}

	private string function _getMachineId() {
		return _machineId;
	}
	private void function _setMachineId() {
		var localHost = CreateObject("java", "java.net.InetAddress").getLocalHost();

		_machineId = Left( localHost.getHostAddress() & "-" & localHost.getHostName(), 255 );
	}

	private struct function _getRunningExports() {
		return _runningExports;
	}
	private void function _setRunningExports( required struct runningExports ) {
		_runningExports = arguments.runningExports;
	}

	private any function _getThreadUtil() {
		return _threadUtil;
	}
	private void function _setThreadUtil( required any threadUtil ) {
		_threadUtil = arguments.threadUtil;
	}
}