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
		var adminLocales = IsTrue( args.adminLocales ?: "" );
		var userDetail   = loginService.getLoggedInUserDetails();

		if ( ArrayLen( locales ) ) {
			var defaultLocale = i18n.getDefaultLocale();
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
				var localeLabel = i18n.getLocaleLabel( locale=locale, defaultLocale=locale );

				return {
					  locale  = arguments.locale
					, title   = localeLabel.title
					, selected = ( arguments.locale == currentLocale )
				}
			} ).sort( function( a, b ){
				return a.title < b.title ? -1 : 1;
			} ).sort( function( a, b ){
				return a.locale == defaultLocale ? -1 : 1;
			} );

			for( var i=1 ; i<=ArrayLen( locales ); i++ ) {
				ArrayAppend( args.values, locales[i].locale );
				ArrayAppend( args.labels, locales[i].title );
			}

			args.defaultValue    = args.defaultValue ?: userDetail.user_language;
			args.multiple        = false;
			args.includeLangAttr = args.includeLangAttr ?: true;
			args.exactMatchOnly  = true;

			if ( args.includeLangAttr ) {
				args.removeObjectPickerClass = args.removeObjectPickerClass ?: true;
				args.extraClasses            = args.extraClasses            ?: "form-control";
				args.optionAttribs           = args.optionAttribs           ?: [];

				if ( IsArray( args.optionAttribs ) && ArrayIsEmpty( args.optionAttribs ) ) {
					for ( var value in args.values ) {
						ArrayAppend( args.optionAttribs, {
							  attribs = { lang=ListChangeDelims( value, "-", "_" ) }
						} );
					}
				}
			}

			return renderView( view="/formcontrols/select/index", args=args );
		}

		return "";
	}

}