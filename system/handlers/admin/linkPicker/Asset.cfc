component {
	private string function getDefaultLinkText( event, rc, prc, args={} ) {
		var assetId = args.asset ?: "";
		if ( assetId.len() ) {
			return renderLabel( "asset", assetId );
		}

		return "";
	}
}