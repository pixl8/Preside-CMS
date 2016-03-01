component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "checkboxList"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
			, values             = ListToArray( args.values ?: "", Chr(10) & Chr(13) )
			, labels             = ListToArray( args.labels ?: "", Chr(10) & Chr(13) )
		);
	}
}