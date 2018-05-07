component {

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkto="usermanager.viewGroup", queryString="id=#( args.recordId ?: "" )#" );
	}

}