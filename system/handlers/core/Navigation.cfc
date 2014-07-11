component output=false {
	property name="siteTreeSvc" inject="siteTreeService";

<!--- VIEWLETS --->
	private string function singleLevelMainNav( event, rc, prc, args={} ) output=false {
		args.homePage  = siteTreeSvc.getSiteHomepage();
		args.menuItems = siteTreeSvc.getDescendants(
			  id       = args.homepage.id
			, depth    = 1
		);

		return renderView( view="core/navigation/singleLevelMainNav", args=args );
	}
}