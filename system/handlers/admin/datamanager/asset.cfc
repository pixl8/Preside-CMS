component {

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkTo="assetmanager.editAsset", querystring="asset=#( args.recordId ?: "" )#" );
	}

}