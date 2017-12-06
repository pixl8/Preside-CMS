component extends="preside.system.modules.cbi18n.models.i18n" output=false {

	property name="resourceBundleService" inject="resourceBundleService";
	property name="resourceService"       inject="resourceService@cbi18n";
	property name="widgetsService"        inject="widgetsService";
	property name="presideObjectService"  inject="presideObjectService";
	property name="controller"            inject="coldbox";

	public any function init() {
		super.init( argumentCollection=arguments );
		return this;
	}

	public void function init_i18n() {
		configure();
		// do nothing to override behaviour we don't want for Preside
	}

	public string function translateResource(
		  required string uri
		,          string defaultValue = variables.controller.getSetting( "UnknownTranslation" )
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
			translated = variables.controller.getWirebox().getInstance( "resourceservice@cbi18n" ).formatRBString(
				  rbString         = translated
				, substituteValues = arguments.data
			);
		}

		return translated;
	}

	public string function getI18nJsForAdmin(){
		var data    = {};
		var bundles = [ "cms" ];
		var locale  = getFwLocale();
		var js = "var _resourceBundle = ( function(){ var rb = {}, bundle, el;";

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

			js &= "bundle = #json#; for( el in bundle ) { rb[el] = bundle[el]; }";
		}

		js &= "return rb; } )();";

		return js;
	}

	public boolean function isValidResourceUri( required string uri ) {
		return resourceBundleService.isValidResourceUri( arguments.uri );
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