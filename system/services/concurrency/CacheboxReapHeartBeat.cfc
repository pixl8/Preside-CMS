/**
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @cachebox.inject                    cachebox
	 * @scheduledThreadpoolExecutor.inject presideScheduledThreadpoolExecutor
	 * @hostname.inject                    coldbox:setting:heartbeats.cacheboxreap.hostname
	 *
	 */
	public function init(
		  required any    scheduledThreadpoolExecutor
		, required any    cachebox
		, required string hostname
		,          string threadName = "Preside Cache Reap Heartbeat"
	){
		_setCachebox( arguments.cachebox );

		super.init(
			  threadName                  = arguments.threadName
			, scheduledThreadpoolExecutor = arguments.scheduledThreadpoolExecutor
			, hostname                    = arguments.hostname
			, intervalInMs                = ( 1000 * 60 ) // 1 minutes
		);

		return this;
	}

	// PUBLIC API METHODS
	public void function $run() {
		try {
			if ( $isInterrupted() ) {
				return;
			}

			_getCachebox().reapAll( force=true );
		} catch( any e ) {
			$raiseError( e );
		}
	}

// GETTERS AND SETTERS
	private any function _getCachebox() {
	    return _cachebox;
	}
	private void function _setCachebox( required any cachebox ) {
	    _cachebox = arguments.cachebox;
	}
}