/**
 * Utility component to help deal with threads started with cfthread.
 * See blog post here: [http://domwatson.codes/2015/01/manipulating-railo-cfthreads.html](http://domwatson.codes/2015/01/manipulating-railo-cfthreads.html)
 *
 * @singleton
 * @autodoc
 */
component displayName="CFThread Helper" {

// PUBLIC API METHODS
	/**
	 * Returns an array of all Java threads running in this container
	 *
	 * @autodoc
	 *
	 */
	public array function getJavaThreads() {
		return CreateObject( "java", "java.lang.Thread" ).getAllStackTraces().keySet().toArray();
	}

	/**
	 * Returns struct of all running CF threads in this container.
	 * i.e. threads started with the cfthread tag. Struct keys
	 * are the name of the thread, values are a struct containing
	 * details of the thread.
	 *
	 * @autodoc
	 *
	 */
	public struct function getRunningThreads() {
		var javaThreads = getJavaThreads();
		var cfthreads   = {};

		for( var thread in javaThreads ) {
			if ( thread.getName() contains "cfthread" ) {
				try {
					var cfThreadScope = thread.getThreadScope();
					cfthreads[ cfThreadScope.name ] = {
						  elapsedtime = cfThreadScope.elapsedtime ?: ""
						, name        = cfThreadScope.name        ?: ""
						, output      = cfThreadScope.output      ?: ""
						, priority    = cfThreadScope.priority    ?: ""
						, starttime   = cfThreadScope.starttime   ?: ""
						, status      = cfThreadScope.status      ?: ""
						, stacktrace  = cfThreadScope.stacktrace  ?: ""
					};
				} catch( any e ) {}
			}
		}

		return cfthreads;
	}

	/**
	 * Terminates a named cfthread using java's thread.interrupt() method.
	 *
	 * @autodoc
	 * @threadName.hint The name of the thread (as specified in the original cfthread tag)
	 * @timeout.hint    Wait for thread to finish for up to timeout value. Do not wait if timeout = 0 (default)
	 */
	public void function terminateThread( required string threadName, numeric timeout=0 ) {
		var javaThreads  = getJavaThreads();
		var cfthreads    = {};
		var isTerminated = function( threadToCheck ) {
			return threadToCheck.getThreadScope().status == "TERMINATED";
		}

		for( var thread in javaThreads ) {
			if ( thread.getName() contains "cfthread" ) {
				try {
					var cfThreadScope = thread.getThreadScope();
					if ( ( cfThreadScope.name ?: "" ) == arguments.threadName ) {
						if ( !isTerminated( thread ) ) {
							thread.interrupt();

							if ( arguments.timeout ) {
								var start    = GetTickCount();
								var timedOut = false;

								do {
									sleep( 5 );
									timedOut = ( GetTickCount() - start ) >= arguments.timeout;

								} while( !timedOut && !isTerminated( thread ) );

								if ( !isTerminated( thread ) ) {
									throw( type="preside.CFThreadHelper", message="Failed to kill task running thread, [#arguments.threadName#], within timeout [#arguments.timeout#ms]" );
								}
							}
						}
						return;
					}
				} catch( any e ) {}
			}
		}
	}
}