component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";
		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "checkbox"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, labels		 	 = args.labels ?: ""
			, defaultValue		 = args.values
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}
}