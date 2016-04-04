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
		var languageRef = { en:  'english (united kingdom)', de : 'german', fr : 'french' };
		return structKeyExists(languageRef,arguments.localeAbbr) ?  languageRef[ arguments.localeAbbr ] : languageRef[ 'en' ];
	}

}