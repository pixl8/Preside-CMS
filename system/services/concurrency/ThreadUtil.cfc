component {

	variables.jvmThread       = CreateObject( "java", "java.lang.Thread" );
	variables.oneHundredYears = 60 * 60 * 24 * 365 * 100;

	public any function getCurrentThread() {
		return jvmThread.currentThread();
	}

	public void function setThreadName( required string name ) {
		getCurrentThread().setName( arguments.name );
	}

	public void function setThreadRequestDefaults() {
		setting enablecfoutputonly=true showdebugoutput=false requesttimeout=oneHundredYears;
	}

	public void function interrupt() {
		if ( !isInterrupted() ) {
			getCurrentThread().interrupt();
		}
	}

	public boolean function isInterrupted() {
		return jvmThread.isInterrupted();
	}

}