component extends="coldbox.system.plugins.i18n" output=false {

	property name="resourceBundleService" inject="resourceBundleService";
	property name="widgetsService"        inject="widgetsService";
	property name="presideObjectService"  inject="presideObjectService";

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

	public string function includei18nResourceBundlesInJsData(){
		var event      = getRequestContext();
		var bundles    = "";
		var bundle     = "";
		var locales    = "";
		var locale     = "";
		var rootFolder = "";
		var newFolder  = "";
		var js         = "";
		var json       = "";

		if ( !event.valueExists( name="_i18nGeneratedForSticker", private=true ) ) {
			event.includeData( {
				resourceBundle = _getBundleData()
			} );
		}
	}

// PRIVATE HEPERS
	private struct function _getBundleData() output=false {
		var data    = {};
		var bundles = [ "cms" ];
		var locale  = getFwLocale();

		for( var widget in widgetsService.getWidgets() ) {
			ArrayAppend( bundles, "widgets." & widget );
		}
		for( var po in presideObjectService.listObjects() ) {
			ArrayAppend( bundles, "preside-objects." & po );
		}

		for( bundle in bundles ) {
			json = resourceBundleService.getBundleAsJson(
				  bundle   = bundle
				, language = ListFirst( locale, "-_" )
				, country  = ListRest( locale, "-_" )
			);

			data.append( DeserializeJson( json ) );
		}

		return data;
	}
}