component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "radio"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, values             = args.values
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}
}