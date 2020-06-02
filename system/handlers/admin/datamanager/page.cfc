component {

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		return buildEditRecordLink( argumentCollection=arguments );
	}

	private string function buildEditRecordLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkTo="sitetree.editPage", querystring="id=#( args.recordId ?: "" )#" );
	}

}