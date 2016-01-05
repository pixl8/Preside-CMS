component output=false {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";

		if ( IsDate( data ) ) {
			return dateFormat( parseDateTime( data ), "dd mmm yyyy" );
		}

		return data;
	}

}