component output=false {

	property name="siteService" inject="siteService";

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