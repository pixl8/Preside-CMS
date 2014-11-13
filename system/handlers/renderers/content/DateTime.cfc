component output=false {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";

		if ( IsDate( data ) ) {
			return getPlugin("i18n").i18nDateTimeFormat( parseDateTime( data ), 1, 2, false );
		}

		return data;
	}

}