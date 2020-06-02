component {

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkto="websiteUserManager.viewUser", queryString="id=" & ( args.recordId ?: "" ) );
	}

}