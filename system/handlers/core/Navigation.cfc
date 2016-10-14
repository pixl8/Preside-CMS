component {
	property name="siteTreeSvc" inject="siteTreeService";

<!--- VIEWLETS --->

	private string function mainNavigation( event, rc, prc, args={} ) {
		var activeTree = ListToArray( event.getPageProperty( "ancestorList" ) );
		    activeTree.append( event.getCurrentPageId() );

		args.menuItems = siteTreeSvc.getPagesForNavigationMenu(
			  rootPage        = args.rootPage     ?: siteTreeSvc.getSiteHomepage().id
			, depth           = args.depth        ?: 1
			, selectFields    = args.selectFields ?: [ "page.id", "page.title", "page.navigation_title", "page.exclude_children_from_navigation" ]
			, includeInactive = event.showNonLiveContent()
			, activeTree      = activeTree
		);

		return renderView( view="core/navigation/mainNavigation", args=args );
	}

	private string function subNavigation( event, rc, prc, args={} ) {
		var startLevel = args.startLevel ?: 2;
		var activeTree = ListToArray( event.getPageProperty( "ancestorList" ) );
		    activeTree.append( event.getCurrentPageId() );

		var rootPageId = activeTree[ startLevel ] ?: activeTree[ 1 ];
		var ancestors  = event.getPageProperty( "ancestors" );

		if ( ancestors.len() >= startLevel ){
			args.rootTitle = Len( Trim( ancestors[ startLevel ].navigation_title ?: "" ) ) ? ancestors[ startLevel ].navigation_title : ancestors[ startLevel ].title;
		} elseif( ( event.getPageProperty( "_hierarchy_depth", 0 ) + 1 ) == startLevel ) {
			args.rootTitle = Len( Trim( event.getPageProperty( "navigation_title", "" ) ) ) ? event.getPageProperty( "navigation_title", "" ) : event.getPageProperty( "title", "" );
		} else {
			args.rootTitle = "";
		}

		args.rootPageId=rootPageId;

		args.menuItems = siteTreeSvc.getPagesForNavigationMenu(
			  rootPage          = rootPageId
			, depth             = args.depth ?: 3
			, includeInactive   = event.showNonLiveContent()
			, activeTree        = activeTree
			, expandAllSiblings = false
			, isSubMenu         = true
		);

		return renderView( view="/core/navigation/subNavigation", args=args );
	}

	private string function htmlSiteMap( event, rc, prc, args={} ) {
		args.tree = siteTreeSvc.getTree(
			  selectFields = [ "page.id", "page.title", "page.active", "page.exclude_from_sitemap" ]
			, format       = "nestedArray"
		);

		return renderView( view="/core/navigation/htmlSiteMap", args=args );
	}
}