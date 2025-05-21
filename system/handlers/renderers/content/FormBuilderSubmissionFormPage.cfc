/**
 * @feature formbuilder
 */
component  {

	property name="formBuilderService" inject="FormBuilderService";

	private string function default( event, rc, prc, args={} ) {
		var pages = _renderContent( argumentCollection=arguments );

		if ( ArrayLen( pages ) ) {
			return '<ul><li>#ArrayToList( pages, "</li><li>" )#</li></ul>';
		}

		return "";
	}

	private string function text( event, rc, prc, args={} ) {
		return ArrayToList( _renderContent( argumentCollection=arguments ) );
	}

	private string function adminDataTable( event, rc, prc, args={} ) {
		args.firstPageOnly = true;
		args.renderedPage  = stripTags( default( argumentCollection=arguments ) );

		return renderView( view="/renderers/content/formBuilderSubmissionFormPage/adminDataTable", args=args );
	}

	private array function _renderContent( event, rc, prc, args={} ) {
		if ( isEmptyString( args.data ?: "" ) ) {
			return [];
		}

		var formId = ( rc.formId ?: ( rc.id ?: ( rc.form ?: ( args.record.form ?: "" ) ) ) );

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

		return renderedPages;
	}

}