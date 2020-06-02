component {
	property name="timeZoneSelectService" inject="TimeZoneSelectService";

	public string function index( event, rc, prc, args={} ) {
		var defaultToSystemTimezone = isTrue( args.defaultToSystemTimezone ?: "" );
		var systemTimeZone          = getTimezone();
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

}