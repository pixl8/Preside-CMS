component output=false {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";

		if ( IsNumeric( data ) ) {
			return LsNumberFormat( data, translateResource( uri="cms:format.integer" ) );
		}

		return data;
	}

}