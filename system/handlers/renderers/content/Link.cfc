component {
	public string function default( event, rc, prc, args={} ){
		var linkId = args.data ?: "";

		if ( linkId.len() ) {
			return renderLink( linkId );
		}

		return "";
	}

	private string function dataExport( event, rc, prc, args={} ) {
		return getLinkUrl( args.data ?: "" );
	}
}