component extends="preside.system.modules.cbi18n.models.i18n" {

	property name="resourceBundleService" inject="delayedInjector:resourceBundleService";
	property name="resourceService"       inject="delayedInjector:resourceService@cbi18n";
	property name="widgetsService"        inject="delayedInjector:widgetsService";
	property name="presideObjectService"  inject="delayedInjector:presideObjectService";
	property name="controller"            inject="delayedInjector:coldbox";
	property name="sessionStorage"        inject="delayedInjector:sessionStorage";
	property name="adminLanguages"        inject="coldbox:setting:adminLanguages";

	variables._localeCache = {};

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
		,          array  data         = []

	) output=false {
		if ( _isDebugMode() ) {
			return arguments.uri;
		}

		var translated = "";

		try {
			translated = resourceBundleService.getResource( argumentCollection = arguments );
		} catch ( "ResourceBundleService.MalformedResourceUri" e ) {
			translated = arguments.defaultValue;
		}

		if ( ArrayLen( arguments.data ) ) {
			translated = resourceservice.formatRBString(
				  rbString         = translated
				, substituteValues = arguments.data
			);
		}

		return translated;
	}

	public string function translateObjectName( required string objectName, boolean plural=false ) {
		var baseUri    = presideObjectService.getResourceBundleUriRoot( arguments.objectName );
		var isPageType = presideObjectService.isPageType( arguments.objectName );
		var uri        = baseUri & ( isPageType ? "name" : "title" );

		if ( !isPageType && !arguments.plural ) {
			uri &= ".singular";
		}

		return translateResource( uri=uri, defaultValue=arguments.objectName );
	}

	public string function translatePropertyName( required string objectName, required string propertyName ) {
		var baseUri = presideObjectService.getResourceBundleUriRoot( arguments.objectName );

		return translateResource(
			  uri          = baseUri & "field.#arguments.propertyName#.title"
			, defaultValue = translateResource( uri="cms:preside-objects.default.field.#arguments.propertyName#.title", defaultValue=arguments.propertyName )
		);
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

		for( var bundle in bundles ) {
			var json = resourceBundleService.getBundleAsJson(
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

	public any function setfwLocale( required string locale ) output=false {
		var event = controller.getRequestService().getContext();
		if ( event.isAdminRequest() && adminLanguages.len() && !adminLanguages.findNoCase( arguments.locale ) ) {
			if ( adminLanguages.len() == 1 ) {
				arguments.locale = adminLanguages[ 1 ];
			} else {
				arguments.locale = controller.getSetting( "default_locale" );
			}
		}

		request._cbfwlocale = arguments.locale;
		StructDelete( request, "_cbFwLanguageCode" );
		StructDelete( request, "_cbFwCountryCode"  );

		return super.setFwLocale( argumentCollection=arguments );
	}

	public any function getFwLocale() {
		if ( !StructKeyExists( request, "_cbfwlocale" ) ) {
			request._cbfwlocale = super.getFwLocale( argumentCollection=arguments );

			var event = controller.getRequestService().getContext();

			if ( event.isAdminRequest() && adminLanguages.len() && !adminLanguages.findNoCase( request._cbfwlocale ) ) {
				if ( adminLanguages.len() == 1 ) {
					request._cbfwlocale = adminLanguages[ 1 ];
				} else {
					request._cbfwlocale = controller.getSetting( "default_locale" );
				}
			}
		}

		return request._cbfwlocale;
	}

	public string function getFWLanguageCode() {
		if ( !StructKeyExists( request, "_cbFwLanguageCode" ) ) {
			request._cbFwLanguageCode = super.getFWLanguageCode();
		}
		return request._cbFwLanguageCode
	}
	public string function getFWCountryCode() {
		if ( !StructKeyExists( request, "_cbFwCountryCode" ) ) {
			request._cbFwCountryCode = super.getFWCountryCode();
		}
		return request._cbFwCountryCode
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

		for( var bundle in bundles ) {
			var json = resourceBundleService.getBundleAsJson(
				  bundle   = bundle
				, language = ListFirst( locale, "-_" )
				, country  = ListRest( locale, "-_" )
			);

			data.append( DeserializeJson( json ) );
		}

		return data;
	}

	private boolean function _isDebugMode() {
		if ( !StructKeyExists( request, "_i18nDebugMode" ) ) {
			request._i18nDebugMode = sessionStorage.getVar( "_i18nDebugMode" );
		}

		request._i18nDebugMode = IsBoolean( request._i18nDebugMode ?: "" ) && request._i18nDebugMode;

		return request._i18nDebugMode;
	}

	private any function buildLocale( string thisLocale="en_US" ) {
		if ( !StructKeyExists( variables._localeCache, arguments.thisLocale ) ) {
			variables._localeCache[ arguments.thisLocale ] = super.buildLocale( argumentCollection=arguments );
		}

		return variables._localeCache[ arguments.thisLocale ];
	}
}