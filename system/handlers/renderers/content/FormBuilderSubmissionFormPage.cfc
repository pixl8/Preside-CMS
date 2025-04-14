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
			}
		}

		if ( ArrayLen( renderedPages ) ) {
			return '<ul><li>#ArrayToList( renderedPages, "</li><li>" )#</li></ul>';
		}

		return "";
	}

}