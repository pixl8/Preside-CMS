component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		return renderFormControl(
			  argumentCollection = args
			, name               = controlName
			, type               = "checkbox"
			, context            = "formbuilder"
			, id                 = args.id                ?: controlName
			, layout             = ""
			, labels		 	 = args.labels            ?: ""
			, checkboxLabel		 = args.checkboxLabel     ?: ""
			, defaultValue		 = IsTrue( args.defaultChecked ?: "" )
			, required           = IsTrue( args.mandatory      ?: "" )
		);
	}

	private string function renderV2ResponsesForDb( event, rc, prc, args={} ) {
		return args.response ?: "";
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		return "shorttext";
	}
}