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
			, required           = IsTrue( args.mandatory ?: "" )
			, values             = replaceNoCase( args.values, chr( 10 ), ',', 'All' ) // chr ( 10 ) means newline
			, labels             = replaceNoCase( args.labels, chr( 10 ), ',', 'All' ) ?: ""
		);
	}
}