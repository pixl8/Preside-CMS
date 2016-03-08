component {

	property name="maintenanceModeService" inject="maintenanceModeService";
	property name="resourceBundleService"  inject="resourceBundleService";
	property name="applicationsService"    inject="applicationsService";
	property name="i18n"                   inject="coldbox:plugin:i18n";

	private string function siteAlerts( event, rc, prc, args={} ) {
		args.inMaintenanceMode = maintenanceModeService.isMaintenanceModeActive();

		return renderView( view="/admin/layout/siteAlerts", args=args );
	}

	private string function localePicker( event, rc, prc, args={} ) {
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

			return renderView( view="/admin/layout/localePicker", args=args );
		}

		return "";
	}

	private string function applicationNav( event, rc, prc, args={} ) {
		args.applications        = applicationsService.listApplications( limitByCurrentUser=true );
		args.selectedApplication = applicationsService.getActiveApplication( event.getCurrentEvent() );

		return renderView( view="/admin/layout/applicationNav", args=args );
	}

	private string function applicationDropdownItem( event, rc, prc, args={} ) {
		var app = args.app ?: "";

		args.append({
			  link        = event.buildLink( linkTo=applicationsService.getDefaultEvent( app ) )
			, title       = translateResource( uri="applications:#app#.title"      , defaultValue=app )
			, description = translateResource( uri="applications:#app#.description", defaultValue="" )
			, iconClass   = translateResource( uri="applications:#app#.iconClass"  , defaultValue="fa-desktop" )
		});

		return renderView( view="/admin/layout/applicationDropdownItem", args=args );
	}
}