component output=false {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";

		if ( IsDate( data ) ) {
			data = parseDateTime( data );
			SetLocale(cookie.defaultlocale);
			return LSDateFormat( data ) & " " & LSTimeFormat( data );
		}

		return data;
	}

}