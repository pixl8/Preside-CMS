component {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";

		if ( IsDate( data ) ) {
			data = parseDateTime( data );
			return dateFormat( data, "dd mmm yyyy" ) & " " & timeFormat( data, "hh:mm:ss tt" );
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