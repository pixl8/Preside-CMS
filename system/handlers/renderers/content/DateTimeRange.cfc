component output=false {

	public string function default( event, rc, prc, args={} ){
		var dateStarted = args.dateStarted ?: "";
		var dateEnded  = args.dateEnded   ?: "";

		var dateStartedFormat = "d mmm yyyy";
		var dateEndedFormat = "d mmm yyyy";

		if ( IsDate( dateStarted ) && IsDate( dateEnded ) ) {
			if ( DateFormat( dateStarted, "yyyy" ) == DateFormat( dateEnded, "yyyy" ) ) {
				dateStartedFormat = Replace( dateStartedFormat, "yyyy", "" );

				if ( DateFormat( dateStarted, "mm" ) == DateFormat( dateEnded, "mm" ) ) {
					dateStartedFormat = Replace( dateStartedFormat, "mmm", "" );
				}
			}

			return DateFormat( dateStarted, dateStartedFormat ) & " - " & DateFormat( dateEnded, dateEndedFormat );
		} else {
			if ( IsDate( dateStarted ) ) {
				return DateFormat( dateStarted, dateStartedFormat );
			}

			if ( IsDate( dateEnded ) ) {
				return DateFormat( dateEnded, dateEndedFormat );
			}
		}

		return "";
	}

}