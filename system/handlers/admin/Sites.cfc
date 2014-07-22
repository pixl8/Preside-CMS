component output=false extends="preside.system.base.AdminHandler" {

	property name="siteService" inject="siteService";

	public void function manage( event, rc, prc ) output=false {
		_checkPermissions( event );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:sites.manage.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="sites.manage" )
		);

		prc.pageIcon     = "globe";
		prc.pageTitle    = translateResource( "cms:sites.manage.title" );
		prc.pageSubTitle = translateResource( "cms:sites.manage.subtitle" );
	}

	public void function setActiveSite( event, rc, prc ) output=false {
		var activeSiteId = rc.id ?: "";

		if ( !Len( Trim( activeSiteId ) ) || !hasPermission( "sites.navigate", "site", [ activeSiteId ] ) ) {
			event.adminAccessDenied();
		}

		siteService.setActiveAdminSite( activeSiteId );

		setNextEvent( url=event.buildAdminLink( linkto="sitetree.index" ) );
	}

	public void function getSitesForAjaxDataTables( event, rc, prc ) output=false {
		_checkPermissions( event );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object      = "site"
				, gridFields  = "name,domain,path"
				, actionsView = "/admin/sites/_sitesGridActions"
			}
		);
	}


// VIEWLETS
	private string function sitePicker( event, rc, prc, struct args={} ) output=false {
		var sites         = siteService.listSites();
		var currentSiteId = event.getSiteId();

		args.sites = [];

		for( var site in sites ){
			if ( hasPermission( "sites.navigate", "site", [ site.id ] ) ) {
				if ( site.id == currentSiteId || ( IsEmpty( currentSiteId ) && sites.currentRow == 1 ) ) {
					args.currentSite = site;
				} else {
					args.sites.append( site );
				}

			}
		}

		return renderView( view="/admin/sites/sitePicker", args=args );
	}

// PRIVATE HELPERS
	private void function _checkPermissions( event ) output=false {
		if ( !hasPermission( "sites.manage" ) ) {
			event.adminAccessDenied();
		}
	}
}