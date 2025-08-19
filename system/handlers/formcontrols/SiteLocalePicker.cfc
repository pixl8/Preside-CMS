/**
 * @feature presideForms and sites
 */
component {

	property name="i18n"              inject="i18n";
	property name="frontendLanguages" inject="coldbox:setting:frontendLanguages";

	public string function index( event, rc, prc, args={} ) output=false {
		args.adminLocales = false;
		args.locales      = frontendLanguages;
		args.defaultValue = args.defaultValue ?: i18n.getDefaultLocale();

		if ( ArrayLen( args.locales ) == 1 ) {
			return "";
		}

		return renderViewlet( event="formcontrols.localePicker.index", args=args );
	}
}