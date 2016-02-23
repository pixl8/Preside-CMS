component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		event.include( assetId="/css/frontend/formbuilder/starRating/" );
		event.include( assetId="/js/frontend/formbuilder/starRating/" );

		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "starRating"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, values             = args.Values
			, halfStar           = args.halfStar ?: 0
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}
}