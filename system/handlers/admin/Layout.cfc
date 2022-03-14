component {

	property name="maintenanceModeService"   inject="maintenanceModeService";
	property name="resourceBundleService"    inject="resourceBundleService";
	property name="adminLanguages"           inject="coldbox:setting:adminLanguages";
	property name="adminSideBarItems"        inject="coldbox:setting:adminSideBarItems";
	property name="adminMenuItemRenderer"    inject="coldbox:setting:adminMenuItemRenderer";
	property name="adminSubMenuItemRenderer" inject="coldbox:setting:adminSubMenuItemRenderer";
	property name="applicationsService"      inject="applicationsService";
	property name="i18n"                     inject="i18n";

	private string function siteAlerts( event, rc, prc, args={} ) {
		args.inMaintenanceMode = maintenanceModeService.isMaintenanceModeActive();

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

	private string function mainMenu( event, rc, prc, args={} ) {
		var items = renderViewlet( event="admin.layout.renderMenuItems", args={
			  menuItems       = adminSideBarItems
			, itemRenderer    = adminMenuItemRenderer
			, subItemRenderer = adminSubMenuItemRenderer
		} );

		return renderView( view="/admin/layout/sideBarNavigation", args={ items=items } );
	}

	private string function renderMenuItems( event, rc, prc, args={} ) {
		var prepared        = isTrue( args.prePepared ?: "" ) ? ( args.menuItems ?: [] ) : prepareMenuItems( argumentCollection=arguments );
		var itemRenderer    = args.itemRenderer ?: adminMenuItemRenderer;
		var subItemRenderer = args.subItemRenderer ?: adminSubMenuItemRenderer;
		var rendered        = [];

		for( var i=1; i<=ArrayLen( prepared ); i++ ) {
			if ( IsSimpleValue( prepared[ i ] ) ) {
				ArrayAppend( rendered, prepared[ i ] );
			} else {
				if ( IsArray( prepared[ i ].subMenuItems ?: "" ) && ArrayLen( prepared[ i ].subMenuItems ) ) {
					prepared[ i ].subMenu = renderMenuItems( argumentCollection=arguments, args={
						  prePepared      = true
						, menuItems       = prepared[ i ].subMenuItems
						, itemRenderer    = subItemRenderer
						, subItemRenderer = subItemRenderer
					} );
				}

				ArrayAppend( rendered, renderViewlet(
					  event = itemRenderer
					, args  = prepared[ i ]
				) );
			}
		}

		return ArrayToList( rendered, " " );
	}

	private array function prepareMenuItems( event, rc, prc, args={} ) {
		var items        = args.menuItems ?: [];
		var prepared     = [];

		for( var item in items ) {
			if ( IsSimpleValue( item ) ) {
				var newStyleHandler = "admin.layout.mainmenu.#item#";
				var oldSchoolView   = "/admin/layout/sidebar/#item#";

				if ( getController().handlerExists( newStyleHandler ) ) {
					ArrayAppend( prepared, runEvent(
						  event         = newStyleHandler
						, private       = true
						, prepostexempt = true
					) );
				} else if ( getController().viewExists( oldSchoolView ) ) {
					ArrayAppend( prepared, renderView( view=oldSchoolView ) );
				} else {
					ArrayAppend( prepared, item );
				}
			} else {
				ArrayAppend( prepared, item );
			}
		}

		for( var i=ArrayLen( prepared ); i>0; i-- ) {
			if ( IsSimpleValue( prepared[ i ] ) ) {
				continue;
			}

			if ( Len( Trim( prepared[ i ].feature ?: "" ) ) && !isFeatureEnabled( prepared[ i ].feature ) ) {
				ArrayDeleteAt( prepared, i );
				continue;
			}
			if ( Len( Trim( prepared[ i ].permissionKey ?: "" ) ) && !hasCmsPermission( prepared[ i ].permissionKey ) ) {
				ArrayDeleteAt( prepared, i );
				continue;
			}

			if ( IsArray( prepared[ i ].subMenuItems ?: "" ) && ArrayLen( prepared[ i ].subMenuItems ) ) {
				prepared[ i ].subMenuItems = prepareMenuItems( argumentCollection=arguments, args={ menuItems=prepared[ i ].subMenuItems } );

				if ( !ArrayLen( prepared[ i ].subMenuItems ) ) {
					ArrayDeleteAt( prepared, i );
					continue;
				}

				for( var subItem in prepared[ i ].subMenuItems ) {
					if ( isTrue( subItem.active ?: "" ) ) {
						prepared[ i ].active = true;
						break;
					}
				}
			}
		}

		return prepared;
	}

	private string function applicationNav( event, rc, prc, args={} ) {
		args.applications        = applicationsService.listApplications( limitByCurrentUser=true );
		args.selectedApplication = applicationsService.getActiveApplication( event.getCurrentEvent() );

		return renderView( view="/admin/layout/applicationNav", args=args );
	}

	private string function applicationDropdownItem( event, rc, prc, args={} ) {
		var app = args.app ?: "";

		args.append({
			  link        = applicationsService.getDefaultUrl( applicationId=app, siteId=event.getSiteId() )
			, title       = translateResource( uri="applications:#app#.title"      , defaultValue=app )
			, description = translateResource( uri="applications:#app#.description", defaultValue="" )
			, iconClass   = translateResource( uri="applications:#app#.iconClass"  , defaultValue="fa-desktop" )
		});

		return renderView( view="/admin/layout/applicationDropdownItem", args=args );
	}
}