/**
 * @feature formBuilder
 */
component {

	private string function renderInput( event, rc, prc, args={} ) {
		event.include( assetId="/css/frontend/formbuilder/starRating/" );
		event.include( assetId="/js/frontend/formbuilder/starRating/" );

		var controlName = args.name ?: "";

		return renderFormControl(
			  argumentCollection = args
			, type               = "starRating"
			, context            = "formbuilder"
			, name               = controlName
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}

	private string function renderV2ResponsesForDb( event, rc, prc, args={} ) {
		if ( Len( args.response ?: "" ) ) {
			return Val( args.response );
		}

		return "";
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		return "float";
	}
}