/**
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @cachebox.inject   cachebox
	 * @threadUtil.inject threadUtil
	 *
	 */
	public function init(
		  required any    threadUtil
		, required any    cachebox
		,          string threadName = "Preside Cache Reap Heartbeat"
	){
		_setCachebox( arguments.cachebox );

		super.init(
			  threadName   = arguments.threadName
			, threadUtil   = arguments.threadUtil
			, intervalInMs = ( 1000 * 60 ) // 1 minutes
		);

		return this;
	}

	// PUBLIC API METHODS
	public void function run() {
		try {
			if ( $isInterrupted() ) {
				return;
			}

			_getCachebox().reapAll( force=true );
		} catch( any e ) {
			$raiseError( e );
		}
	}

	public void function startInNewRequest() {
		var startUrl = _buildInternalLink( linkTo="taskmanager.runtasks.startCacheReapHeartbeat" );

		thread name=CreateUUId() startUrl=startUrl {
			do {
				try {
					sleep( 20478 );
					http method="post" url=startUrl timeout=20 throwonerror=true {}
					success = true;
				} catch( any e ) {
					$raiseError( e );
					$systemOutput( "Failed to start cache reap heartbeat. Retrying...(attempt #attempt#)");
				}
			} while ( !success && ++attempt <= 10 );
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