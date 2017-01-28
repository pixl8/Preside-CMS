component output=false extends="coldbox.system.logging.AbstractAppender" {

// CONSTRUCTOR
	public any function init( required string name, struct properties = {}, string layout = "", numeric levelMin = 0, numeric levelMax = 4 ) output=false {
		return super.init( argumentCollection = arguments );
	}

// PUBLIC API METHODS
	public void function logMessage( required any logEvent ) output=false {
		var e              = arguments.logEvent;
		var extraInfo      = e.getExtraInfo();
		var taskRunId      = extraInfo.taskRunId      ?: "";
		var taskHistoryDao = extraInfo.taskHistoryDao ?: "";

		if ( Len( Trim( taskRunId ) ) && IsObject( taskHistoryDao ) ) {
			var history = taskHistoryDao.selectData( id=taskRunId, selectFields=[ "log" ] );
			if ( history.recordCount ) {
				var message = "[#super.severityToString( e.getSeverity() )#] [#DateFormat( e.getTimeStamp(), 'yyyy-mm-dd' )# #TimeFormat( e.getTimeStamp(), 'HH:mm:ss' )#]: #e.getMessage()#" & Chr(10);

				taskHistoryDao.updateData( id=taskRunId, data={
					log = ListAppend( history.log, message, Chr(10) )
				} );
			}
		}
	}
}