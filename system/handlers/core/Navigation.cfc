component output=false {
	property name="siteTreeSvc" inject="siteTreeService";

<!--- VIEWLETS --->

	private string function mainNavigation( event, rc, prc, args={} ) output=false {
		var activeTree = Duplicate( event.getPageProperty( "ancestors" ) );
		activeTree.prepend( event.getCurrentPageId() );

		args.menuItems = siteTreeSvc.getPagesForNavigationMenu(
			  rootPage        = args.rootPage ?: siteTreeSvc.getSiteHomepage().id
			, depth           = args.depth    ?: 1
			, includeInactive = event.isAdminUser()
			, activeTree      = activeTree
		);

		return renderView( view="core/navigation/mainNavigation", args=args );
	}
}