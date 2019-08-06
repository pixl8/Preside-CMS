component {
	public string function index( event, rc, prc, args={} ) {
		return renderView( view="formcontrols/siteTreePageSlugEditor/index", args=args );
	}

	public string function getParentPage( event, rc, prc, args={} ) {
		parentSlug = event.buildLink( page=( rc.parent_page ?: "" ) );
		return left( parentSlug, len( parentSlug )-5 ) & '/';
	}
}