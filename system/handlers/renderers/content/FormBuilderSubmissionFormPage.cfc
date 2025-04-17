/**
 * @feature formbuilder
 */
component  {

	property name="formBuilderService" inject="FormBuilderService";

	private string function default( event, rc, prc, args={} ) {
		if ( isEmptyString( args.data ?: "" ) ) {
			return "";
		}

		var formId = ( rc.formId ?: ( rc.id ?: ( rc.form ?: "" ) ) );

		var renderedPages = [];
		var pages         = formBuilderService.getPages( formId=formId );

		for ( var page in pages ) {
			if ( ListContains( args.data, page.id ) ) {
				ArrayAppend( renderedPages, page.configuration.label );

				if ( isTrue( args.firstPageOnly ?: "" ) ) {
					break;
				}
			}
		}

		if ( ArrayLen( renderedPages ) ) {
			return '<ul><li>#ArrayToList( renderedPages, "</li><li>" )#</li></ul>';
		}

		return "";
	}

	private string function adminDataTable( event, rc, prc, args={} ) {
		args.firstPageOnly = true;
		args.renderedPage  = stripTags( default( argumentCollection=arguments ) );

		return renderView( view="/renderers/content/formBuilderSubmissionFormPage/adminDataTable", args=args );
	}

}