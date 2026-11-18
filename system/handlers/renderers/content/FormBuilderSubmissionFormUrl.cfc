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

				if ( Left( args.data, 1 ) != "/" ) {
					return EncodeForHTML( args.data );
				}

				var link = event.getSiteUrl( submission.form_site ) & args.data;

				return '<a href="#EncodeForHTMLAttribute( link )#">#EncodeForHTML( link )#</a>';
			}
		}

		return "";
	}

}