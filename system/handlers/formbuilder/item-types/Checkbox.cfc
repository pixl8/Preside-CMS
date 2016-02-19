component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";
		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "checkbox"
			, context            = "formbuilder"
			, id                 = args.id                ?: controlName
			, layout             = ""
			, labels		 	 = args.labels            ?: ""
			, checkboxLabel		 = args.checkboxLabel     ?: ""
			, defaultValue		 = 1
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}
}