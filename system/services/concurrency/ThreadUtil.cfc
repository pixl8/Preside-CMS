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

	public void function interrupt( any thethread=getCurrentThread() ) {
		if ( !arguments.thethread.isInterrupted() ) {
			arguments.thethread.interrupt();
		}
	}

	public void function shutdownThread( any thethread=getCurrentThread(), numeric interruptWait=10000, any logger ) {
		var maxAttempts = arguments.interruptWait / 100;
		var attempt     = 0;
		var canLog      = arguments.keyExists( "logger" );
		var canWarn     = canLog && logger.canWarn();
		var canError    = canLog && logger.canError();
		var threadName  = arguments.theThread.getName();

		if ( canWarn ) { logger.warn( "Interrupt signal sent to running task." ); }

		interrupt( arguments.theThread );

		while( ++attempt <= maxAttempts && !isTerminated( arguments.theThread ) ) {
			log file="application" text="Waiting to gracefully shutdown thread [#threadName#]. Current state: #arguments.thethread.getState().name()#";
			if ( canWarn ) { logger.warn( "Waiting to gracefully shutdown task. Current state: #arguments.thethread.getState().name()#" ); }
			sleep( 100 );
		}

		if ( isTerminated( arguments.thethread ) ) {
			log file="application" text="Thread [#threadName#] gracefully shutdown.";
			if ( canWarn ) { logger.warn( "Task gracefully shutdown." ); }
		} else {
			log file="application" text="Thread [#threadName#] did not gracefully terminate. Forcefully stopping it.";
			if ( canWarn ) { logger.warn( "Task did not gracefully terminate after #( arguments.interruptWait / 1000 )# seconds. Forcefully stopping it." ); }

			try {
				theThread.getPageContext().release();
			} catch( any e ) {}
			theThread.stop();
			sleep( 100 );

			if ( isTerminated( arguments.theThread ) ) {
				log file="application" text="Thread [#threadName#] terminated.";
				if ( canWarn ) { logger.warn( "Task terminated." ); }
			} else {
				log file="application" text="Thread [#threadName#] failed to terminate!";
				if ( canError ) { logger.error( "Task failed to terminate." ); }

			}
		}
	}

	public boolean function isInterrupted() {
		return jvmThread.isInterrupted();
	}

	public boolean function isTerminated( any thethread=getCurrentThread() ) {
		var state = theThread.getState().name();

		return state == "TERMINATED"
	}

}