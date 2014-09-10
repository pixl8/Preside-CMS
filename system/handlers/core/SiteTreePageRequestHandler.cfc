component output=false {

	property name="pageTypesService"     inject="pageTypesService";
	property name="presideObjectService" inject="presideObjectService";

	public function index( event, rc, prc ) output=false {
		event.initializePresideSiteteePage(
			  slug      = ( prc.slug      ?: "/" )
			, subAction = ( prc.subAction ?: "" )
		);

		var pageId       = event.getCurrentPageId();
		var pageType     = event.getPageProperty( "page_type" );
		var layout       = event.getPageProperty( "layout", "index" );
		var validLayouts = event.getPageProperty( "layout", "index" );

		// todo, something much better here...
		if ( !Len( Trim( pageId ) ) || !pageTypesService.pageTypeExists( pageType ) || ( !event.isCurrentPageActive() && !event.isAdminUser() ) ) {
			event.renderData( data="Not found", type="plain", statusCode=404 );
			return;
		}

		pageType = pageTypesService.getPageType( pageType );
		if ( !Len( Trim( layout ) )  ) {
			validLayouts = pageType.listLayouts();
			layout       = validLayouts.len() == 1 ? validLayouts[1] : "index";
		}

		if ( pageType.hasHandler() && getController().handlerExists( pageType.getViewlet() & "." & layout ) ) {
			rc.body = renderViewlet( pageType.getViewlet() & "." & layout );
		} else {
			rc.body = renderView(
				  view          = "page-types/#pageType.getId()#/#layout#"
				, presideObject = pageType.getPresideObject()
				, filter        = { page = pageId }
				, groupby       = pageType.getPresideObject() & ".id" // ensure we only get a single record should the view be joining on one-to-many relationships
			);
		}

		event.setView( "/core/simpleBodyRenderer" );
	}
}