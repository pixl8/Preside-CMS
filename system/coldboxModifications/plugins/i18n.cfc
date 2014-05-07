component extends="coldbox.system.plugins.i18n" output=false {

	property name="resourceBundleService" inject="resourceBundleService";

	public string function translateResource(
		  required string uri
		,          string defaultValue = getController().getSetting( "UnknownTranslation" )
		,          string language     = getFWLanguageCode()
		,          string country      = getFWCountryCode()
		,          array  data = []

	) output=false {
		var translated = "";

		try {
			translated = resourceBundleService.getResource( argumentCollection = arguments );
		} catch ( "ResourceBundleService.MalformedResourceUri" e ) {
			translated = arguments.defaultValue;
		}

		if ( ArrayLen( arguments.data ) ) {
			translated = getController().getPlugin( "ResourceBundle" ).formatRBString(
				  rbString         = translated
				, substituteValues = arguments.data
			);
		}

		return translated;
	}
}