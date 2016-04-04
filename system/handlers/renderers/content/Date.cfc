component output=false {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";

		if ( IsDate( data ) ) {
			data = parseDateTime( data );
			SetLocale( _getLocaleStringFromAbbr( cookie.defaultlocale ) );
			return LSDateFormat( data );
		}

		return data;
	}

	private string function _getLocaleStringFromAbbr( required string localeAbbr ) {
		if( localeAbbr == 'en' ){
			return 'english (united kingdom)';
		} else if( localeAbbr == 'de' ){
			return 'dutch';
		} else if( localeAbbr == 'fr' ){
			return 'french';
		}
	}

}