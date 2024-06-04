/**
 * @feature admin
 */
component {

	property name="maintenanceModeService"   inject="maintenanceModeService";
	property name="resourceBundleService"    inject="resourceBundleService";
	property name="adminMenuItemService"     inject="adminMenuItemService";
	property name="adminLanguages"           inject="coldbox:setting:adminLanguages";
	property name="adminSideBarItems"        inject="coldbox:setting:adminSideBarItems";
	property name="environmentBannerConfig"  inject="coldbox:setting:environmentBannerConfig";
	property name="environmentMessage"       inject="coldbox:setting:environmentMessage";
	property name="applicationsService"      inject="applicationsService";
	property name="i18n"                     inject="i18n";

	private string function environmentBanner( event, rc, prc, args={} ) {
		var shouldDisplay = isTrue( environmentBannerConfig.display ?: true );

		if ( !shouldDisplay ) {
			return "";
		}

		var environment   = controller.getConfigSettings().environment;
		var envDefaultMsg = translateResource(
			  uri          = "cms:environment.#environment#.label"
			, defaultValue = translateResource( uri="cms:environment.default.label", data=[ UCase( environment ) ] )
		);

		args.iconClass = environmentBannerConfig.icon     ?: "";
		args.cssClass  = environmentBannerConfig.cssClass ?: "alert-danger";
		args.message   = Len( Trim( environmentMessage ) ) ? environmentMessage : ( environmentBannerConfig.message ?: envDefaultMsg );

		return renderView( view="/admin/layout/environmentBanner", args=args );
	}

	private string function siteAlerts( event, rc, prc, args={} ) {
		args.inMaintenanceMode = maintenanceModeService.isMaintenanceModeActive();

		runEvent( event="admin.systemAlerts.displayCriticalAlerts", private=true, prePostExempt=true );

		return renderView( view="/admin/layout/siteAlerts", args=args );
	}

	private string function localePicker( event, rc, prc, args={} ) {
		args.locales = adminLanguages.len() ? adminLanguages : Duplicate( resourceBundleService.listLocales() );

		if ( args.locales.len() ) {
			var defaultLocale = i18n.getDefaultLocale();
			var currentLocale = i18n.getfwLocale();

			if ( !adminLanguages.len() && !args.locales.findNoCase( "en" ) ) {
				args.locales.append( "en" );
			}

			if ( args.locales.len() > 1 ) {
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

				args.baseUrl = event.buildAdminLink( linkto="general.setLocale", queryString="locale=" );

				return renderView( view="/admin/layout/localePicker", args=args );
			}
		}

		return "";
	}

	private string function adminMenu( event, rc, prc, args={} ) {
		var preparedMenuItems = adminMenuItemService.prepareMenuItemsForRequest(
			  menuItems      = args.menuItems      ?: adminSideBarItems
			, legacyViewBase = args.legacyViewBase ?: "/admin/layout/sidebar/"
		);

		return renderViewlet( event="admin.layout.renderMenuItems", args={
			  menuItems        = preparedMenuItems
			, itemRenderer     = args.itemRenderer     ?: "admin.layout.sidebar._menuItem"
			, subItemRenderer  = args.subItemRenderer  ?: "admin.layout.sidebar._submenuItem"
			, itemRendererArgs = args.itemRendererArgs ?: {}
		} );
	}

	private string function renderMenuItems( event, rc, prc, args={} ) {
		var items           = args.menuItems        ?: [];
		var itemRenderer    = args.itemRenderer     ?: "admin.layout.sidebar._menuItem";
		var subItemRenderer = args.subItemRenderer  ?: "admin.layout.sidebar._submenuItem";
		var rendererArgs    = args.itemRendererArgs ?: {}
		var rendered        = [];

		for( var i=1; i<=ArrayLen( items ); i++ ) {
			if ( IsSimpleValue( items[ i ] ) ) {
				ArrayAppend( rendered, items[ i ] );
			} else if ( Len( Trim( items[ i ].view ?: "" ) ) ) {
				ArrayAppend( rendered, renderView( view=items[ i ].view ) );
			} else {
				if ( IsArray( items[ i ].subMenuItems ?: "" ) && ArrayLen( items[ i ].subMenuItems ) ) {
					items[ i ].subMenu = renderMenuItems( argumentCollection=arguments, args={
						  menuItems       = items[ i ].subMenuItems
						, itemRenderer    = subItemRenderer
						, subItemRenderer = subItemRenderer
						, itemRendererArgs = rendererArgs
					} );
				}

				var args = StructCopy( items[ i ] );
				StructAppend( args, rendererArgs, false );

				ArrayAppend( rendered, renderViewlet(
					  event = itemRenderer
					, args  = args
				) );
			}
		}

		return ArrayToList( rendered, " " );
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