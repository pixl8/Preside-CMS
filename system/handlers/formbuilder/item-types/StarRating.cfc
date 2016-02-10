component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		event.include( assetId="/css/admin/frontend/" );
		event.include( assetId="/js/frontend/formbuilder/starRating/" );

		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "starRating"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, values             = args.Values
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}
}