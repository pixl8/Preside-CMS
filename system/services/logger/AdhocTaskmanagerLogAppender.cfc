/**
 * @nowirebox true
 */
component extends="coldbox.system.logging.AbstractAppender" {

// CONSTRUCTOR
	public any function init(
		  required string  name
		,          struct  properties = {}
		,          string  layout     = ""
		,          numeric levelMin   = 0
		,          numeric levelMax   = 4
	) output=false {
		return super.init( argumentCollection = arguments );
	}

// PUBLIC API METHODS
	public void function logMessage( required any logEvent ) output=false {
		var extraInfo = arguments.logEvent.getExtraInfo();
		var taskRunId = extraInfo.taskRunId ?: "";

		if ( !Len( Trim( taskRunId ) ) || !_setup( extraInfo ) ) {
			return;
		}

		var q = new Query();
		q.setDatasource( variables._logInfo.dsn );
		q.setSQL( variables._logInfo.sql );
		q.addParam( name="task"    , value=taskRunId                               , cfsqltype="cf_sql_varchar" );
		q.addParam( name="ts"      , value=_ts( arguments.logEvent.getTimestamp() ), cfsqltype="cf_sql_bigint"  );
		q.addParam( name="severity", value=arguments.logEvent.getSeverity()        , cfsqltype="cf_sql_int"     );
		q.addParam( name="line"    , value=arguments.logEvent.getMessage()         , cfsqltype="cf_sql_varchar" );
		q.execute();
	}

// private helpers
	private function _setup( extraInfo ) {
		if ( !StructKeyExists( variables, "_logInfo" ) ) {
			if ( !StructKeyExists( arguments.extraInfo, "taskHistoryDao" ) ) {
				return false;
			}

			var taskHistoryDao = arguments.extraInfo.taskHistoryDao ?: "";
			var adapter        = taskHistoryDao.getDbAdapter();
			var tableName      = adapter.escapeEntity( taskHistoryDao.getTableName() );
			var taskCol        = adapter.escapeEntity( "task" );
			var tsCol          = adapter.escapeEntity( "ts" );
			var severityCol    = adapter.escapeEntity( "severity" );
			var lineCol        = adapter.escapeEntity( "line" );

			variables._logInfo = {
				  sql       = "insert into #tableName# ( #taskCol#, #tsCol#, #severityCol#, #lineCol# ) values ( :task, :ts, :severity, :line )"
				, dsn       = taskHistoryDao.getDsn()
			};
		}

		return true;
	}

	private function _ts( datetime ) {
		return DateDiff( 's', '1970-01-01 00:00:00', arguments.datetime );
	}
}