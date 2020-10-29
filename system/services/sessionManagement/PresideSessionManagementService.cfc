/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public void function reap() {
		var reaped = $getPresideObject( "session_storage" ).deleteData(
			  filter       = "expiry < :expiry"
			, filterParams = { expiry=_getUnixTimeStamp() }
		);

		if ( reaped ) {
			$SystemOutput( "Reaped [#NumberFormat( reaped )#] expired Preside sessions." );
		}
	}

	public numeric function getActiveSessionCount() {
		return $getPresideObject( "session_storage" ).selectData(
			  filter          = "expiry >= :expiry"
			, filterParams    = { expiry=_getUnixTimeStamp() }
			, selectFields    = [ "1 as record" ]
			, recordCountOnly = true
		);
	}

// PRIVATE HELPERS
	private numeric function _getUnixTimeStamp() {
		var epochInMs = CreateObject( "java", "java.time.Instant" ).now().toEpochMilli();

		return Ceiling( epochInMs / 1000  );
	}

}