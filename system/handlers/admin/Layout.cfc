component {

	property name="maintenanceModeService" inject="maintenanceModeService";
	property name="resourceBundleService"  inject="resourceBundleService";
	property name="i18n"                   inject="coldbox:plugin:i18n";

	private string function siteAlerts( event, rc, prc, args={} ) {
		args.inMaintenanceMode = maintenanceModeService.isMaintenanceModeActive();

		return renderView( view="/admin/layout/siteAlerts", args=args );
	}

	private string function loginLocalePicker( event, rc, prc, args={} ) {
		args.locales = Duplicate( resourceBundleService.listLocales() );

		if ( args.locales.len() ) {
			var defaultLocale = i18n.getDefaultLocale();
			var currentLocale = i18n.getfwLocale();

			args.locales.append( defaultLocale );
			args.locales = args.locales.map( function( locale ){
				var language = ListFirst( locale, "_" );
				var country  = ListLen( locale, "_" ) > 1 ? ListRest( locale, "_" ) : "";

				return {
					  locale  = arguments.locale
					, title   = translateResource( uri="locale:title", language=language, country=country )
					, flag    = translateResource( uri="locale:flag" , language=language, country=country )
					, selected = ( arguments.locale == currentLocale )
				}
			} ).sort( function( a, b ){
				if ( a.locale == defaultLocale ) {
					return -1;
				}

				return a.title < b.title ? -1 : 1;
			} );

			args.selectedLocale = args.locales[1];
			args.locales.each(function( locale ){
				if ( locale.locale == currentLocale ) {
					args.selectedLocale = locale;
					break;
				}
			});

			return renderView( view="/admin/layout/loginLocalPicker", args=args );
		}

		return "";
	}
}