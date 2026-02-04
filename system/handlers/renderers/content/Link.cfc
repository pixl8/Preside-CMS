/**
 * @feature cms
 */
component {
	property name="linksService" inject="LinksService";

	public string function default( event, rc, prc, args={} ){
		var linkId = args.data ?: "";

		if ( linkId.len() ) {
			return renderLink( linkId );
		}

		return "";
	}

	private string function dataExport( event, rc, prc, args={} ) {
		var link = getPresideObject( "link" ).selectData( id=args.data ?: "" );

		if ( !link.recordCount ) {
			return "Link not found";
		}

		return linksService.getLinkUrl( link.id );
	}

}