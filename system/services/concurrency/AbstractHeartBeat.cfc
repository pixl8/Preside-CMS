component {

// CONSTRUCTOR
	public any function init(
		  required string  threadName
		, required numeric intervalInMs
		,          any     threadUtil = new ThreadUtil()
	) {
		_setThreadName( arguments.threadName );
		_setIntervalInMs( arguments.intervalInMs );
		_setThreadUtil( arguments.threadUtil );
		_setStopped( true );

		return this;
	}

	public void function run() {
		throw( type="preside.AbstractHeartBeat.method.not.implemented", message="Implementing sub-classes must implement their own RUN method." );
	}

	public void function start() {
		if ( _isStopped() ) {
			thread name="#_getThreadName()#-#CreateUUId()#" {
				register();

				do {
					sleep( _getIntervalInMs() );
					run();

					request.delete( "__cacheboxRequestCache" );

					content reset=true;
				} while( !_isStopped() );
			}
		}
	}

	public void function shutdown(){
		stop();
	}

	public void function stop() {
		interrupt();
		deregister();
	}

	public void function interrupt() {
		_getThreadUtil().shutdownThread(
			  theThread     = _getRunningThread()
			, interruptWait = 10000
		);
	}

	public void function register() {
		try {
			var tu = _getThreadUtil();

			tu.setThreadName( _getThreadName() );
			tu.setThreadRequestDefaults();

			_setRunningThread( tu.getCurrentThread() );
			_setStopped( false );
		} catch( any e ) {
			systemOutput( e );
		}
	}

	public void function deregister() {
		_setRunningThread( NullValue() );
		_setStopped( true );
	}

// PRIVATE HELPERS
	private void function _setThreadName() {
		var theThread = CreateObject( "java", "java.lang.Thread" ).currentThread();

		theThread.setName( "PresideAdhocTaskManagerHeartBeat" );
	}

// GETTERS / SETTERS
	private string function _getThreadName() {
		return _threadName;
	}
	private void function _setThreadName( required string threadName ) {
		_threadName = arguments.threadName;
	}

	private any function _getIntervalInMs() {
		return _intervalInMs;
	}
	private void function _setIntervalInMs( required any intervalInMs ) {
		_intervalInMs = arguments.intervalInMs;
	}

	private any function _getThreadUtil() {
		return _threadUtil;
	}
	private void function _setThreadUtil( required any threadUtil ) {
		_threadUtil = arguments.threadUtil;
	}

	private any function _getRunningThread() {
		return _runningThread ?: NullValue();
	}
	private void function _setRunningThread( any runningThread ) {
		_runningThread = arguments.runningThread ?: NullValue();
	}

	private boolean function _isStopped() {
		return _stopped || _getThreadUtil().isInterrupted();
	}
	private void function _setStopped( required boolean stopped ) {
		_stopped = arguments.stopped;
	}
}