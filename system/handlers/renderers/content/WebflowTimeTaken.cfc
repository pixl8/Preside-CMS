component {

	public string function default( event, rc, prc, args={} ) {
		var rendered  = "";
		var timeTaken = Val( Trim( args.data ?: "" ) );
		var processed = _convertTimeToFormat( timeTaken=timeTaken );
		var i18nKey   = "sec";

		if ( processed.minutes > 0 ) {
			i18nKey &= "_min";

			if ( processed.hours > 0 ) {
				i18nKey &= "_hour";

				if ( processed.days > 0 ) {
					i18nKey &= "_day";
				}
			}
		}

		return translateResource( uri="cms:time.period.duration.#i18nKey#", data=[
			  processed.seconds
			, processed.minutes
			, processed.hours
			, processed.days
		] );
	}

	private struct function _convertTimeToFormat( required numeric timeTaken ) {
		var totalSeconds = arguments.timeTaken;
		var processed    = {
			  days    = 0
			, hours   = 0
			, minutes = 0
			, seconds = arguments.timeTaken
		};

		if ( processed.seconds > 86400 ) {
			processed.days  = Floor( processed.seconds / 86400 );
			processed.hours = processed.seconds = processed.seconds - ( processed.days * 86400 );
		}

		if ( processed.seconds > 3600 ) {
			processed.hours   = Floor( processed.seconds / 3600 );
			processed.minutes = processed.seconds = processed.seconds - ( processed.hours * 3600 );
		}

		if ( processed.seconds > 60 ) {
			processed.minutes = Floor( processed.seconds / 60 );
			processed.seconds = processed.seconds = Int( processed.seconds % 60 );
		}

		return processed;
	}
}