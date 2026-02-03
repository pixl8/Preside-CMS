/**
 * @feature formbuilder
 */
component  {

	property name="formBuilderService" inject="SiteService";
	property name="formBuilderService" inject="FormBuilderService";

	private string function default( event, rc, prc, args={} ) {
		if ( !isEmptyString( args.data ?: "" ) ) {
			var submissionId = ( rc.submissionId ?: ( args.record.id ?: ( rc.id ?: "" ) ) );

			var submission = formBuilderService.getSubmission( submissionId );

			if ( !isEmptyString( submission.form_site ?: "" ) ) {

				var link = event.getSiteUrl( submission.form_site ) & args.data;

				return '<a href="#link#">#link#</a>';
			}
		}

		return "";
	}

}