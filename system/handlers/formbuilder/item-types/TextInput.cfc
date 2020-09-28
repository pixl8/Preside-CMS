component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		return renderFormControl(
			  argumentCollection = args
			, name               = controlName
			, type               = "textinput"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}

	private string function renderV2ResponsesForDb( event, rc, prc, args={} ) {
		return args.response ?: "";
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		var maxLength = Val( args.configuration.maxlength ?: "" );

		if ( maxLength && maxLength <= 200 ) {
			return "shorttext";
		}

		return "text";
	}
}