component output=false {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";

		if ( LSisDate( data ) ) {
			return LSdateFormat( LSparseDateTime( data ), translateResource( uri="cms:dateFormat" ) );
		}

		return data;
	}

}