component {

	private string function index( event, rc, prc, args={} ) {
		var inputName    = args.name ?: "";
		var defaultValue = args.defaultValue ?: "";
		var value        = rc[ inputName ] ?: defaultValue;

		if ( !IsSimpleValue( value ) ) {
			value = "";
		}

		try {
			args.timePeriod = DeserializeJson( value );
		} catch ( any e ) {
			args.timePeriod = {
				  type    = "alltime"
				, unit    = ""
				, measure = ""
				, date1   = ""
				, date2   = ""
			};
		}

		event.include( "/js/admin/specific/timePeriodPicker/"  )
		     .include( "/css/admin/specific/timePeriodPicker/" );

		return renderView( view="/formControls/timePeriodPicker/index", args=args );
	}

}