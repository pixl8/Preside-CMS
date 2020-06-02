/**
 * Provides thread related helper methods.
 *
 * @autodoc        true
 * @presideService true
 * @singleton      true
 */
component {

	variables.jvmThread       = CreateObject( "java", "java.lang.Thread" );
	variables.oneHundredYears = 60 * 60 * 24 * 365 * 100;

	public any function init() {
		return this;
	}

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
	 * Sets some sensible defaults for background threads. Turns
	 * off debug output and sets the request timeout to 100 years.
	 *
	 * @autodoc true
	 *
	 */
	public void function setThreadRequestDefaults() {
		setting showdebugoutput=false requesttimeout=oneHundredYears;
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
	 * Interrupts the given thread by setting a Lucee
	 * variable that the thread could respond to. Hence, super soft!
	 *
	 * @autodoc   true
	 * @theThread Java object representing the thread to interrupt
	 *
	 */
	public boolean function softInterrupt( any thethread=getCurrentThread() ) {
		if ( !arguments.thethread.isInterrupted() ) {
			try {
				var requestScope = getRequestScope( arguments.theThread );
				requestScope.__softInterrupted = true;
			} catch( any e ) {
				return false;
			}

			return true;
		}

		return false;
	}

	/**
	 * Gets the request scope of the given cfthread thread object
	 *
	 * @autodoc   true
	 * @theThread Java object representing the cfthread whose request scope you wish to get
	 */
	public any function getRequestScope( required any theThread ) {
		return arguments.theThread.getPageContext().scope( "request", NullValue() );
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
		var maxAttempts = arguments.interruptWait / 200;
		var attempt     = 0;
		var canLog      = StructKeyExists( arguments, "logger" );
		var canWarn     = canLog && logger.canWarn();
		var canError    = canLog && logger.canError();
		var threadName  = arguments.theThread.getName();

		if ( canWarn ) { logger.warn( "Interrupt signal sent to running task." ); }

		if ( !isSleeping( theThread ) ) {
			$systemOutput( "Attempting to soft shutdown the thread, [#theThread.getName()#]." );
			if ( softInterrupt( arguments.theThread ) ) {
				while( ++attempt <= maxAttempts && !isTerminated( arguments.theThread ) ) {
					if ( attempt > 1 ) {
						$systemOutput( "Waiting to gracefully shutdown thread [#threadName#]. Current state: #arguments.thethread.getState().name()#" );
						if ( canWarn ) { logger.warn( "Waiting to gracefully shutdown task. Current state: #arguments.thethread.getState().name()#" ); }
					}
					sleep( 100 );
				}
				if ( isTerminated( arguments.thethread ) ) {
					$systemOutput( "The thread [#threadName#], has gracefully shutdown." );
					if ( canWarn ) { logger.warn( "Task gracefully shutdown." ); }
					return;
				}
			}
			$systemOutput( "Failed to soft shutdown #theThread.getName()# in a timely manner." );
		} else {
			maxAttempts = maxAttempts*2;
		}

		attempt=0;
		$systemOutput( "Attempting to shutdown the thread, [#theThread.getName()#] using an interrupt." );
		interrupt( arguments.theThread );
		while( ++attempt <= maxAttempts && !isTerminated( arguments.theThread ) ) {
			if ( attempt > 1 ) {
				$systemOutput( "Waiting to gracefully shutdown thread [#threadName#]. Current state: #arguments.thethread.getState().name()#" );
				if ( canWarn ) { logger.warn( "Waiting to gracefully shutdown task. Current state: #arguments.thethread.getState().name()#" ); }
			}
			sleep( 100 );
		}

		if ( isTerminated( arguments.thethread ) ) {
			$systemOutput( "The thread [#threadName#], has gracefully shutdown." );
			if ( canWarn ) { logger.warn( "Task has gracefully shutdown." ); }
			return;
		}

		try {
			theThread.getPageContext().release();
		} catch( any e ) {}

		$systemOutput( "The thread [#threadName#], failed to gracefully shutdown!" );
		if ( canError ) { logger.error( "Task failed to gracefully shutdown!" ); }
	}

	/**
	 * Whether or not the current thread is interrupted.
	 *
	 * @autodoc true
	 *
	 */
	public boolean function isInterrupted() {
		return ( IsBoolean( request.__softInterrupted ?: "" ) && request.__softInterrupted ) || jvmThread.currentThread().isInterrupted();
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

		return state == "TERMINATED";
	}

	/**
	 * Whether or not the given thread is currently sleeping
	 *
	 * @autodoc   true
	 * @thethread The thread (java object) to check
	 *
	 */
	public boolean function isSleeping( any thethread=getCurrentThread() ) {
		var state = theThread.getState().name();

		if ( state == "TIMED_WAITING" ) {
			var trace = theThread.getStackTrace();

			try {
				var isSleep = trace[ 1 ].getMethodName() == "sleep";
				return isSleep;
			} catch( any e ) {}
		}

		return false;
	}

}