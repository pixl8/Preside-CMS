/**
 * @feature presideForms
 */
component {
	property name="timeZoneSelectService" inject="TimeZoneSelectService";

	public string function index( event, rc, prc, args={} ) {
		var defaultToSystemTimezone = isTrue( args.defaultToSystemTimezone ?: "" );
		var systemTimeZone          = _getTimezoneName();
		var timeZones               = timeZoneSelectService.getTimeZones();

		args.values = [ "" ];
		args.labels = [ "" ];

		if ( !len( args.defaultValue ?: "" ) && defaultToSystemTimezone ) {
			args.defaultValue = systemTimeZone;
		}

		for( var timeZone in timeZones ) {
			args.values.append( timeZone.id );
			args.labels.append( "(" & translateResource( uri="formcontrols.timeZoneSelect:utc.label" ) & timeZone.formattedOffset & ") " & timeZone.id & " - " & timeZone.name );
		}

		return renderView( view="/formcontrols/select/index", args=args );
	}

	// necessary because Lucee 5 -> 6 has incompatible change due to
	// ACF introducing a different getTimeZone() function which we
	// used to use
	private function _getTimezoneName() {
		var tzInfo = getTimezoneInfo();

		return tzInfo.id;
	}
}