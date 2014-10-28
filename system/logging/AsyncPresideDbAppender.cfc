component output=false extends="PresideDbAppender" {

	public void function logMessage( required any logEvent ) output=false {
		if ( super.getUtil().inThread() ) {
			return super.logMessage( argumentCollection=arguments );
		}

		var threadName = "#super.getName()#_logMessage_#Replace( CreateUUId(), "-", "", "all" )#";

		thread name=threadName e=arguments.logEvent {
			super.logMessage( attributes.e );
		}
	}
}