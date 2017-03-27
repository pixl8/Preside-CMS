component output=false {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";

		if ( IsDate( data ) ) {
			return TimeFormat( parseDateTime( data ), "HH:mm" );
		}

		return data;
	}

}