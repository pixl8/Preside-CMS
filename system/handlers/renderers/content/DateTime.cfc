component output=false {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";

		if ( IsDate( data ) ) {
			data = parseDateTime( data );
			return dateFormat( data, "dd mmm yyyy" ) & " " & timeFormat( data, "hh:mm:ss tt" );
		}

		return data;
	}

}