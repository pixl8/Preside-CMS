component {
	public string function index( event, rc, prc, args={} ) {
		var parentPage = rc.parent_page ?: ( prc.page.parent_page ?: "" );

		if ( Len( Trim( parentPage ) ) ) {
			args.parentSlug = event.buildLink( page=parentPage ).reReplace( "\.html$", "/" );
		} else {
			args.parentSlug = "/";
		}
		return renderView( view="formcontrols/siteTreePageSlugEditor/index", args=args );
	}

	public string function getParentPage( event, rc, prc, args={} ) {
		var parentSlug = event.buildLink( page=( rc.parent_page ?: "" ) );

		return parentSlug.reReplace( "\.html$", "/" );
	}
}