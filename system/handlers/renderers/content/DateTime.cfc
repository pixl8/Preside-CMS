component output=false {

	public string function default( event, rc, prc, viewletArgs={} ){
		var data = viewletArgs.data ?: "";

		if ( IsDate( data ) ) {
			return getPlugin("i18n").i18nDateTimeFormat( data, 1, 2, false );
		}

		return data;
	}

}