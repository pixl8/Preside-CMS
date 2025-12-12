component output=false {

	public string function default( event, rc, prc, args={} ){
		var data             = args.data ?: "";
		var adminUserDetails = event.getAdminUserDetails();
		var dateFormatMask   = translateResource( uri="cms:dateFormat");
		var timeFormatMask  = translateResource( uri="cms:timeFormat");
		
		if ( IsStruct(adminUserDetails) ) {
			if ( Len( adminUserDetails.user_admin_date_format ?: "" ) ) {
				dateFormatMask = adminUserDetails.user_admin_date_format;
			}

			if( Len( adminUserDetails.user_time_format ?: "" ) ) {
				if ( adminUserDetails.user_time_format == "24h" ) {
					timeFormatMask = "HH:mm:ss";
				} else {
					timeFormatMask = "hh:mm:ss tt";
				}
			}
		}

		if ( LSIsDate( data ) ) {
			data = LSparseDateTime( data );
			return LSdateFormat( LSparseDateTime( data ), dateFormatMask ) & " " & LStimeFormat( data, timeFormatMask );
		}

		return data;
	}

	private string function relative( event, rc, prc, args={} ) {
		var then = args.data ?: "";

		if ( isDate( then ) ) {
			return _justNowFormat( then );
		}

		return "";
	}

	private string function _justNowFormat( required string then ) {
		var rightNow = Now();
		var i        = "";

		i = DateDiff( 'yyyy', then, rightNow );
		if ( i ) { return translateResource( uri="cms:relative.date.years.#( i>1 ? 'multiple' : 'singular' )#", data=[ i ] ); }

		i = DateDiff( 'm', then, rightNow );
		if ( i ) { return translateResource( uri="cms:relative.date.months.#( i>1 ? 'multiple' : 'singular' )#", data=[ i ] ); }

		i = DateDiff( 'w', then, rightNow );
		if ( i ) { return translateResource( uri="cms:relative.date.weeks.#( i>1 ? 'multiple' : 'singular' )#", data=[ i ] ); }

		i = DateDiff( 'd', then, rightNow );
		if ( i ) { return translateResource( uri="cms:relative.date.days.#( i>1 ? 'multiple' : 'singular' )#", data=[ i ] ); }

		i = DateDiff( 'h', then, rightNow );
		if ( i ) { return translateResource( uri="cms:relative.date.hours.#( i>1 ? 'multiple' : 'singular' )#", data=[ i ] ); }

		i = DateDiff( 'n', then, rightNow );
		if ( i ) { return translateResource( uri="cms:relative.date.minutes.#( i>1 ? 'multiple' : 'singular' )#", data=[ i ] ); }

		return translateResource( uri="cms:relative.date.just.now" );
	}

}