component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";
		event.include( assetId="/js/frontend/formbuilder/select/" );
		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "select"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
			, multiple 			 = args.multiple ?: 0
			, values 			 = args.values
			, class 			 = "form-control"
			, labels			 = args.Labels ?: ""
		);
	}
}