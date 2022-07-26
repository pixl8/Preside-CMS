component {

	private string function buildListingLink( event, rc, prc, args={} ) {
		return event.buildAdminLink(
			  linkto      = "formbuilder.submissions"
			, queryString = "id=" & ( rc.formId ?: "" )
		);
	}

}
