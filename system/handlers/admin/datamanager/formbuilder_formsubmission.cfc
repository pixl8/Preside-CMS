/**
 * @feature admin and formbuilder
 */
component {
	private string function buildListingLink( event, rc, prc, args={} ) {
		return event.buildAdminLink(
			  linkTo      = "formbuilder.submissions"
			, queryString = "id=" & ( rc.formId ?: "" )
		);
	}
}