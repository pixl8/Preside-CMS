/**
 * @feature presideForms and sites
 */
component {

	property name="i18n"                  inject="i18n";
	property name="frontendLanguages"     inject="coldbox:setting:frontendLanguages";
	property name="resourceBundleService" inject="resourceBundleService";

	public string function index( event, rc, prc, args={} ) output=false {
		args.extraClasses = "site-locale-picker";
		args.adminLocales = false;
		args.locales      = frontendLanguages;
		args.defaultValue = args.defaultValue ?: i18n.getDefaultLocale();

		if ( ArrayLen( args.locales ) == 1 ) {
			return "";
		}

		var isoCountriesJson = resourceBundleService.getBundleAsJson(
			bundle   = "enum.isoCountries"
		);

		var defaultLocaleSettings = getSetting( "datetime.regionDefaults" );

		event.includeData( {
			  isoCountries = deserializeJson(isoCountriesJson)
			, defaultLocaleSettings = defaultLocaleSettings
		} );

		event.include( "/js/admin/specific/siteLocalePicker/" );

		return renderViewlet( event="formcontrols.localePicker.index", args=args );
	}
}