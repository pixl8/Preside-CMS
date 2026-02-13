/**
 * @feature presideForms and sites
 */
component {

	property name="i18n"                  inject="i18n";
	property name="frontendLanguages"     inject="coldbox:setting:frontendLanguages";
	property name="defaultLocaleSettings" inject="coldbox:setting:datetime.regionDefaults";
	property name="resourceBundleService" inject="resourceBundleService";

	public string function index( event, rc, prc, args={} ) {
		args.extraClasses = args.extraClasses ?: "";
		args.extraClasses = ListAppend( args.extraClasses, "site-locale-picker", " " );
		args.adminLocales = false;
		args.locales      = frontendLanguages;
		args.defaultValue = args.defaultValue ?: i18n.getDefaultLocale();

		if ( ArrayLen( args.locales ) == 1 ) {
			return "";
		}

		var isoCountriesJson = resourceBundleService.getBundleAsJson( bundle="enum.isoCountries" );

		event.includeData( {
			  isoCountries          = DeserializeJson( isoCountriesJson )
			, defaultLocaleSettings = defaultLocaleSettings
		} );

		event.include( "/js/admin/specific/siteLocalePicker/" );

		return renderViewlet( event="formcontrols.localePicker.index", args=args );
	}

	public string function admin( event, rc, prc, args={} ) {
		args.extraClasses = args.extraClasses ?: "";
		if ( !ReFindNoCase( "form-control", args.extraClasses ) ) {
			args.extraClasses = ListAppend( args.extraClasses, "form-control", " " );
		}

		return index( argumentCollection=arguments );
	}
}