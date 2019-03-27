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
		var e              = arguments.logEvent;
		var extraInfo      = e.getExtraInfo();
		var taskRunId      = extraInfo.taskRunId      ?: "";
		var taskHistoryDao = extraInfo.taskHistoryDao ?: "";

		if ( Len( Trim( taskRunId ) ) && IsObject( taskHistoryDao ) ) {
			var adapter   = taskHistoryDao.getDbAdapter();
			var tableName = adapter.escapeEntity( taskHistoryDao.getTableName() );
			var colName   = adapter.escapeEntity( "log" );
			var idCol     = adapter.escapeEntity( "id" );
			var message   = "[#super.severityToString( e.getSeverity() )#] [#DateFormat( e.getTimeStamp(), 'yyyy-mm-dd' )# #TimeFormat( e.getTimeStamp(), 'HH:mm:ss' )#]: #e.getMessage()#" & Chr(10);
			var sql       = "update #tableName# set #colName# = #adapter.getConcatenationSql( "coalesce( #colName#, '' )", ':log' )# where #idCol# = :id";
			var q         = new Query();

			q.setDatasource( taskHistoryDao.getDsn() );
			q.addParam( name="log", value=message  , cfsqltype="cf_sql_varchar" );
			q.addParam( name="id" , value=taskRunId, cfsqltype="cf_sql_varchar" );
			q.setSQL( sql );
			q.execute();
		}
	}
}