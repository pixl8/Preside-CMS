/**
 * Provides thread related helper methods.
 *
 * @autodoc
 */
component {

	variables.jvmThread       = CreateObject( "java", "java.lang.Thread" );
	variables.oneHundredYears = 60 * 60 * 24 * 365 * 100;

	/**
	 * Gets the Java object representing the current thread
	 *
	 * @autodoc true
	 *
	 */
	public any function getCurrentThread() {
		return jvmThread.currentThread();
	}

	/**
	 * Sets the name of the current thread. e.g.
	 * \n
	 * ```luceescript
	 * threadUtil.setThreadName( "My special thread" )
	 * ```
	 *
	 * @autodoc true
	 * @name    The name you would like to set.
	 *
	 */
	public void function setThreadName( required string name ) {
		getCurrentThread().setName( arguments.name );
	}

	/**
	 * Sets some sensible defaults for background threads. Sets
	 * cfoutputonly to true, turns off debug output and sets
	 * the request timeout to 100 years.
	 *
	 * @autodoc true
	 *
	 */
	public void function setThreadRequestDefaults() {
		setting enablecfoutputonly=true showdebugoutput=false requesttimeout=oneHundredYears;
	}

	/**
	 * Interrupts the given thread, allowing it to gracefully shutdown.
	 *
	 * @autodoc   true
	 * @theThread Java object representing the thread to interrupt
	 *
	 */
	public void function interrupt( any thethread=getCurrentThread() ) {
		if ( !arguments.thethread.isInterrupted() ) {
			arguments.thethread.interrupt();
		}
	}

	/**
	 * Attempts to gracefully end the given thread, reverting
	 * to forceful shutdown if the thread does not shutdown
	 * in the given time frame
	 *
	 * @autodoc       true
	 * @theThread     Java object representing the thread to shutdown
	 * @interruptWait How long, in ms, to wait for the thread to gracefully end before brutally shutting down.
	 * @logger        Optional logger. If present, will log the attempts to shutdown the thread.
	 *
	 */
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

	/**
	 * Whether or not the current thread is interrupted.
	 *
	 * @autodoc true
	 *
	 */
	public boolean function isInterrupted() {
		return jvmThread.isInterrupted();
	}

	/**
	 * Whether or not the given thread has been terminated.
	 *
	 * @autodoc   true
	 * @thethread The thread (java object) to check
	 *
	 */
	public boolean function isTerminated( any thethread=getCurrentThread() ) {
		var state = theThread.getState().name();

		return state == "TERMINATED"
	}

}