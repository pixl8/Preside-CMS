component output=false {

	public string function default( event, rc, prc, viewletArgs={} ){
		var data = viewletArgs.data ?: "";

		if ( IsDate( data ) ) {
			return getPlugin("i18n").i18nDateFormat( data, 1 );
		}

		return data;
	}

}