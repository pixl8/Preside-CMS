/**
 * @singleton      true
 * @presideService true
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @threadUtil.inject delayedInjector:threadUtil
	 */
	public any function init(
		  required string  threadName
		, required numeric intervalInMs
		,          any     threadUtil
		,          string  feature = ""
	) {
		_setThreadName( arguments.threadName );
		_setIntervalInMs( arguments.intervalInMs );
		_setThreadUtil( arguments.threadUtil );
		_setStopped( true );
		_setFeature( arguments.feature );

		return this;
	}

	public void function run() {
		throw( type="preside.AbstractHeartBeat.method.not.implemented", message="Implementing sub-classes must implement their own RUN method." );
	}

	public void function start() {
		if( _isFeatureDisabled() ) {
			return;
		}

		if ( _isStopped() || _hasStoppedInError() ) {
			thread name="#_getThreadName()#-#CreateUUId()#" {
				lock type="exclusive" timeout=1 name=_getThreadName() {
					if ( _isStopped() || _hasStoppedInError() ) {
						register();
					}
				}

				while( !_isStopped() ) {
					run();

					if ( _isStopped() ) {
						break;
					}

					request.delete( "__cacheboxRequestCache" );
					content reset=true;

					sleep( _getIntervalInMs() );
				};

				$systemOutput( "The #_getThreadName()# heartbeat thread has gracefully exited after being told to stop." );

				deregister();
			}
		}
	}

	public void function startInNewRequest() {
		// must be implemented by concrete classes
	}



	public void function shutdown(){
		if ( !_isStopped() ) {
			stop();
		}
	}

	public void function stop() {
		shutdownThread();
		deregister();
	}

	public void function shutdownThread() {
		var runningThread = _getRunningThread();

		if ( !IsNull( runningThread ) ) {
			_getThreadUtil().shutdownThread(
				  theThread     = runningThread
				, interruptWait = 10000
			);
		}
	}

	public void function register() {
		try {
			var tu = _getThreadUtil();

			tu.setThreadName( _getThreadName() );
			tu.setThreadRequestDefaults();

			_setRunningThread( tu.getCurrentThread() );
			_setStopped( false );
			_registerInApplication();
		} catch( any e ) {
			$systemOutput( e );
		}
	}

	public void function deregister() {
		_setRunningThread( NullValue() );
		_setStopped( true );
		_deRegisterFromApplication();
	}

	public void function ensureAlive() {
		if ( _hasStoppedInError() ) {
			$systemOutput( "The #_getThreadName()# heartbeat thread has stopped in error. Attempting restart now." );
			startInNewRequest();
		}
	}

// PRIVATE HELPERS
	private string function _buildInternalLink() {
		var buildLinkArgs         = arguments;
		var maintenanceModeActive = _getMaintenanceModeService().isMaintenanceModeActive();

		if ( $isFeatureEnabled( "sites" ) ) {
			buildLinkArgs.site = _getTaskRunnerSite();
		}

		if ( maintenanceModeActive ) {
			var settings   = _getMaintenanceModeService().getMaintenanceModeSettings();
			var bypassUuid = settings.bypassUuid ?: "";
			buildLinkArgs.querystring = listAppend( buildLinkArgs.querystring ?: "", "heartbeatBypass=#bypassUuid#", "&" );
		}
		var link = $getRequestContext().buildLink( argumentCollection=buildLinkArgs );

		if ( link.reFindNoCase( "^https" ) && !$isFeatureEnabled( "sslInternalHttpCalls" ) ) {
			return link.reReplaceNoCase( "^https", "http" );
		}

		return link;
	}

	private string function _getTaskRunnerSite() {
		var configuredSite = $getPresideSetting( "taskmanager", "site_context" );

		if ( Len( Trim( configuredSite ) ) ) {
			return configuredSite;
		}

		var firstSite = $getPresideObject( "site" ).selectData(
			  selectFields = [ "id" ]
			, orderBy = "datecreated"
			, maxRows = 1
		);

		return firstSite.id ?: "";
	}

	private void function _registerInApplication() {
		application._presideHeartbeatThreads = application._presideHeartbeatThreads ?: {};
		application._presideHeartbeatThreads[ _getThreadName() ] = this;
	}

	private void function _deregisterFromApplication() {
		application._presideHeartbeatThreads = application._presideHeartbeatThreads ?: {};
		application._presideHeartbeatThreads.delete( _getThreadName() );
	}

	private boolean function _hasStoppedInError() {
		if ( _isStopped() ) {
			return false;
		}

		var crashed = false;
		try {
			var theThread = _getRunningThread();
			if ( IsNull( local.theThread ) ) {
				crashed = true;
			} else {
				crashed = !theThread.isAlive();
			}
		} catch( any e ) {
			crashed = true;
		}

		return crashed;
	}

	private boolean function _isFeatureDisabled() {
		var feature = _getFeature();

		return Len( Trim( feature ) ) && !$featureIsEnabled( feature );
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

	private any function _getThreadUtil() {
		return _threadUtil;
	}
	private void function _setThreadUtil( required any threadUtil ) {
		_threadUtil = arguments.threadUtil;
	}

	private any function _getMaintenanceModeService() {
		if ( isNull( _maintenanceModeService ) ) {
			_setMaintenanceModeService( $getColdbox().getWirebox().getInstance( "MaintenanceModeService" ) );
		}
		return _maintenanceModeService;
	}
	private void function _setMaintenanceModeService( required any maintenanceModeService ) {
		_maintenanceModeService = arguments.maintenanceModeService;
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

	private string function _getFeature() {
	    return _feature;
	}
	private void function _setFeature( required string feature ) {
	    _feature = arguments.feature;
	}
}