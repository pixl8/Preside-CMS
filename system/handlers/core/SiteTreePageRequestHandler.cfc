component {

	property name="pageTypesService"              inject="pageTypesService";
	property name="websiteUserActionService"      inject="websiteUserActionService";
	property name="delayedViewletRendererService" inject="delayedViewletRendererService";

	public function index( event, rc, prc ) output=false {
		announceInterception( "preRenderSiteTreePage" );

		event.initializePresideSiteteePage(
			  slug               = ( prc.slug      ?: "/" )
			, subAction          = ( prc.subAction ?: "" )
		);

		announceInterception( "postInitializePresideSiteteePage" );

		var pageId       = event.getCurrentPageId();
		var pageType     = event.getPageProperty( "page_type" );
		var layout       = event.getPageProperty( "layout", "index" );
		var validLayouts = event.getPageProperty( "layout", "index" );
		var viewlet      = "";
		var view         = "";

		if ( !Len( Trim( pageId ) ) || !pageTypesService.pageTypeExists( pageType ) || ( !event.isCurrentPageActive() && !event.showNonLiveContent() ) ) {
			event.notFound();
		}

		websiteUserActionService.recordAction(
			  action     = "pagevisit"
			, type       = "request"
			, identifier = pageId
			, userId     = getLoggedInUserId()
		);

		event.checkPageAccess();

		pageType = pageTypesService.getPageType( pageType );
		if ( !Len( Trim( layout ) ) && !pageType.isSystemPageType() ) {
			validLayouts = pageType.listLayouts();
			layout       = validLayouts.len() == 1 ? validLayouts[1] : "index";
		}

		if ( pageType.isSystemPageType() ) {
			viewlet = pageType.getViewlet();
			view    = Replace( pageType.getViewlet(), ".", "/", "all" );
		} else {
			viewlet = pageType.getViewlet();
			view    = "page-types/#pageType.getId()#/#layout#";

			if ( viewlet.reFindNoCase( "\.index$" ) ) {
				if ( layout != "index" ) {
					 viewlet = viewlet.reReplaceNoCase( "index$", layout );
				}
			} else if ( getController().viewletExists( viewlet & "." & layout ) ) {
				viewlet = viewlet & "." & layout;
			}
		}

		if ( pageType.hasHandler() && getController().handlerExists( viewlet ) ) {
			var delayed = delayedViewletRendererService.isViewletDelayedByDefault(
				  viewlet      = viewlet
				, defaultValue = pageType.isSystemPageType() // system page types should be delayed by default
			);

			rc.body = renderViewlet( event=viewlet, prePostExempt=false, delayed=delayed );
		} else {
			rc.body = renderView(
				  view          = view
				, presideObject = pageType.getPresideObject()
				, filter        = { page = pageId }
			);
		}

		event.setView( "/core/simpleBodyRenderer" );

		event.setXFrameOptionsHeader();

		announceInterception( "postRenderSiteTreePage" );
	}
}