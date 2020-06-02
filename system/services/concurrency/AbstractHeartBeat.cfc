/**
 * @singleton      true
 * @presideService true
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @scheduledThreadpoolExecutor.inject presideScheduledThreadpoolExecutor
	 */
	public any function init(
		  required string  threadName
		, required numeric intervalInMs
		, required any     scheduledThreadpoolExecutor
		,          string  feature  = ""
		,          string  hostname = cgi.server_name
	) {
		_setThreadName( arguments.threadName );
		_setIntervalInMs( arguments.intervalInMs );
		_setScheduledThreadpoolExecutor( arguments.scheduledThreadpoolExecutor );
		_setFeature( arguments.feature );
		_setHostname( arguments.hostname );

		return this;
	}

	public void function run() {
		$getRequestContext().autoSetSiteByHost();
		$run();
		setLastRun();
	}

	public void function $run() {
		throw( type="preside.AbstractHeartBeat.method.not.implemented", message="Implementing sub-classes must implement their own $run() method." );
	}

	public void function start() {
		if( _isFeatureDisabled() ) {
			return;
		}

		if ( _isStopped() ) {
			var tpe = _getScheduledThreadpoolExecutor();

			if ( !tpe.isStarted() ) {
				tpe.start();
			}

			var taskFuture = tpe.scheduleAtFixedRate(
				  id           = _getThreadName()
				, task         = this
				, initialDelay = 0
				, period       = _getIntervalInMs()
				, timeUnit     = tpe.getObjectFactory().MILLISECONDS
				, hostname     = _getHostname()
			);

			setStartTime();

			$systemOutput( "Started #_getThreadName()# heartbeat with hostname: #_getHostname()#" );

			_setTaskFuture( taskFuture );
		}
	}

	public void function shutdown(){
		if ( !_isStopped() ) {
			stop();
		}
	}

	public void function stop() {
		var taskFuture = _getTaskFuture();

		$systemOutput( "Shutting down #_getThreadName()# heartbeat." );
		_getScheduledThreadpoolExecutor().cancelTask( _getThreadName() );

		for( var i=1; i<=10; i++ ) {
			if ( taskFuture.isDone() || taskFuture.isCancelled() ) {
				$systemOutput( "Successfully shut down #_getThreadName()# heartbeat." );
				break;
			}
		}

		if ( !taskFuture.isDone() && !taskFuture.isCancelled() ) {
			$systemOutput( "FAILED TO SHUTDOWN #_getThreadName()#" );
		}
	}

	public date function getLastRun() {
	    return _lastRun ?: CreateDate( 1900, 1, 1 );
	}
	public void function setLastRun( date lastRun=Now() ) {
	    _lastRun = arguments.lastRun;
	}

	public numeric function getUptime() {
		return GetTickCount() - getStartTime();
	}

	public numeric function getStartTime() {
	    return _startTime ?: GetTickCount();
	}
	public void function setStartTime( numeric startTime=GetTickCount() ) {
	    _startTime = arguments.startTime;
	}

// PRIVATE HELPERS
	private boolean function _isFeatureDisabled() {
		var feature = _getFeature();

		return Len( Trim( feature ) ) && !$isFeatureEnabled( feature );
	}

	private boolean function _isStopped() {
		var taskFuture = _getTaskFuture();

		return IsNull( local.taskFuture ) || taskFuture.isDone() || taskFuture.isCancelled();
	}

// GETTERS / SETTERS
	private string function _getThreadName() {
		return _threadName;
	}
	private void function _setThreadName( required string threadName ) {
		var appSettings = getApplicationMetadata();
		var appName = appSettings.PRESIDE_APPLICATION_ID ?: ( appSettings.name ?: "" );
		_threadName = appName.len() ? "#arguments.threadName# (#appName#)" : arguments.threadName;
	}

	private any function _getIntervalInMs() {
		return _intervalInMs;
	}
	private void function _setIntervalInMs( required any intervalInMs ) {
		_intervalInMs = arguments.intervalInMs;
	}

	private any function _getScheduledThreadpoolExecutor() {
	    return _scheduledThreadpoolExecutor;
	}
	private void function _setScheduledThreadpoolExecutor( required any scheduledThreadpoolExecutor ) {
	    _scheduledThreadpoolExecutor = arguments.scheduledThreadpoolExecutor;
	}

	private string function _getFeature() {
	    return _feature;
	}
	private void function _setFeature( required string feature ) {
	    _feature = arguments.feature;
	}

	private any function _getTaskFuture() {
	    return _taskFuture ?: NullValue();
	}
	private void function _setTaskFuture( required any taskFuture ) {
	    _taskFuture = arguments.taskFuture;
	}

	private string function _getHostname() {
	    return _hostname;
	}
	private void function _setHostname( required string hostname ) {
	    _hostname = arguments.hostname;
	}
}