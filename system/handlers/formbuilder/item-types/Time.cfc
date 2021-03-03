component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = arguments.args.name ?: "";

		return renderFormControl(
			  argumentCollection = arguments.args
			, name               = controlName
			, type               = "timepicker"
			, context            = "formbuilder"
			, id                 = arguments.args.id ?: controlName
			, layout             = ""
			, required           = isTrue( arguments.args.mandatory ?: "" )
		);
	}

	private array function getValidationRules( event, rc, prc, args={} ) {
		var rules = [];

		return rules;
	}

	private string function renderV2ResponsesForDb( event, rc, prc, args={} ) {
		return arguments.args.response ?: "";
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		return "time";
	}
}