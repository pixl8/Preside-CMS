component output=false {

	public string function default( event, rc, prc, args={} ){
		var clicks     = args.data         ?: 0;
		var record     = args.record       ?: {};
		var sentCount  = record.sent_count ?: 0;
		var rate       = 0;

		if ( sentCount > 0 ) {
			rate = ( clicks / sentCount ) * 100;
		}

		rate = NumberFormat( rate, "99.9" ) & "%";

		return translateResource(
			  uri  = "preside-objects.email_template:field.click_rate.value"
			, data = [ rate, clicks ]
		);
	}
}