component output=false {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";

		if ( IsDate( data ) ) {
			return getPlugin("i18n").i18nDateFormat( data, 1 );
		}

		return data;
	}

}