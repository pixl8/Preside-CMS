/**
 * @feature presideForms
 */
component {

	property name="resourceBundleService"  inject="resourceBundleService";
	property name="i18n"                   inject="i18n";
	property name="loginService"           inject="loginService";
	property name="adminLanguages"         inject="coldbox:setting:adminLanguages";

	public string function index( event, rc, prc, args={} ) {
		var allLocales   = resourceBundleService.listLocales()
		var locales      = Duplicate( args.locales ?: allLocales );
		var checkLocales = IsTrue( args.checkLocales ?: "" );
		var adminLocales = IsTrue( args.adminLocales ?: "" );
		var userDetail   = loginService.getLoggedInUserDetails();

		if ( ArrayLen( locales ) ) {
			var defaultLocale    = i18n.getDefaultLocale();
			var defaultLangTitle = translateResource(
				  uri      = "locale:title"
				, language = ListFirst( defaultLocale, "_" )
				, country  = ListLen( defaultLocale, "_" ) > 1 ? ListRest( defaultLocale, "_" ) : ""
			);

			var currentLocale = i18n.getfwLocale();
			args.values       = [];
			args.labels       = [];

			if ( !ArrayFindNoCase( locales, defaultLocale ) ) {
				ArrayAppend( locales, defaultLocale );
			}

			if ( adminLocales && ArrayLen( adminLanguages ) ) {
				for( var i=ArrayLen( locales ); i>0; i-- ) {
					if ( !ArrayFindNoCase( adminLanguages, locales[ i ] ) ) {
						ArrayDeleteAt( locales, i );
					}
				}
			}

			locales = locales.map( function( locale ){
				var language = ListFirst( locale, "_" );
				var country  = ListLen( locale, "_" ) > 1 ? ListRest( locale, "_" ) : "";
				var title    = translateResource( uri="locale:title", language=language, country=country );

				if ( checkLocales && ( locale != "en" ) ) {
					if ( !ArrayFindNoCase( allLocales, locale ) || ( title == defaultLangTitle ) ) {
						title = locale;
					}
				}

				return {
					  locale  = arguments.locale
					, title   = title
					, selected = ( arguments.locale == currentLocale )
				}
			} ).sort( function( a, b ){
				if ( a.locale == defaultLocale ) {
					return -1;
				}

				return a.title < b.title ? -1 : 1;
			} );

			for( var i=1 ; i<=ArrayLen( locales ); i++ ) {
				ArrayAppend( args.values, locales[i].locale );
				ArrayAppend( args.labels, locales[i].title );
			}

			args.defaultValue = args.defaultValue ?: userDetail.user_language;
			args.multiple     = false;

			return renderView( view="/formcontrols/select/index", args=args );
		}

		return "";
	}

}