component {

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkto="usermanager.viewUser", queryString="id=#( args.recordId ?: "" )#" );
	}

}