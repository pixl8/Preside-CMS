/**
 * @presideService true
 * @singleton      true
 */
component {

	variables.epoch = CreateDate( 1970, 1, 1 );

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
		var utcNow = DateConvert( "local2utc", Now() );

		return DateDiff( 's', epoch, utcNow );
	}

}