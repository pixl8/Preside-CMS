component output=false {

	property name="siteService" inject="siteService";

	public void function setActiveSite( event, rc, prc ) output=false {
		var activeSiteId = rc.id ?: "";

		if ( !Len( Trim( activeSiteId ) ) || !hasPermission( "sites.navigate", "site", [ activeSiteId ] ) ) {
			event.adminAccessDenied();
		}

		siteService.setActiveAdminSite( activeSiteId );

		setNextEvent( url=event.buildAdminLink( linkto="sitetree.index" ) );
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
}