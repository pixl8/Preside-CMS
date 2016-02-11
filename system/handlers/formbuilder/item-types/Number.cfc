component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";
		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "number"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
			, class				 = ""
			, minValue			 = args.minValue
			, maxValue			 = args.maxValue
		);
	}
}