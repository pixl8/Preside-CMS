/**
 * @feature presideForms and siteTree
 */
component {
	public string function index( event, rc, prc, args={} ) {
		var parentPage = rc.parent_page ?: ( prc.page.parent_page ?: "" );

		if ( Len( Trim( parentPage ) ) ) {
			var parentUrl   = event.buildLink(
				  page        = parentPage
				, siteId      = rc._sid ?: ""
				, forceDomain = true
			);
			args.parentSlug = reReplace( parentUrl, "\.html(\?.*)?$", "/" );
		} else {
			args.parentSlug = "/";
		}
		return renderView( view="formcontrols/siteTreePageSlugEditor/index", args=args );
	}

	public string function getParentPage( event, rc, prc, args={} ) {
		var parentUrl = event.buildLink(
			  page        = rc.parent_page ?: ""
			, siteId      = rc._sid ?: ""
			, forceDomain = true
		);

		return reReplace( parentUrl, "\.html(\?.*)?$", "/" );
	}
}