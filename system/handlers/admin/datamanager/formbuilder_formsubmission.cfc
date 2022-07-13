component {

	property name="formBuilderService" inject="FormBuilderService";

	private string function buildListingLink( event, rc, prc, args={} ) {


		return event.buildAdminLink(
			  linkto      = "formbuilder.submissions"
			, queryString = "id=" & ( rc.formId ?: "" )
		);
	}
}
