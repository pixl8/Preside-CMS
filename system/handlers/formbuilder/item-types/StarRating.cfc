component {

	private string function renderInput( event, rc, prc, args={} ) {
		event.include( assetId="/css/frontend/formbuilder/starRating/" );
		event.include( assetId="/js/frontend/formbuilder/starRating/" );

		return renderFormControl(
			  argumentCollection = args
			, type               = "starRating"
			, context            = "formbuilder"
			, id                 = args.id ?: ( args.name ?: "" )
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}
}