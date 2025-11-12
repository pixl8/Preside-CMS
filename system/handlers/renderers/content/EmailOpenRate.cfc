component output=false {

	property name="emailStatsService" inject="emailStatsService";

	public string function default( event, rc, prc, args={} ){
		var opens      = args.data   ?: 0;
		var record     = args.record ?: {};
		var templateId = record.id  ?: "";
		var rate       = 0;

		if ( Len( templateId ) && Val( opens ) > 0 ) {
			var sendCount = emailStatsService.getSendCountStat( templateId=templateId );

			if ( sendCount > 0 ) {
				rate = ( opens / sendCount ) * 100;
			}
		}

		rate = NumberFormat( rate, "99.9" ) & "%";

		return translateResource(
			  uri  = "preside-objects.email_template:field.open_rate.value"
			, data = [ rate, opens ]
		);
	}
}