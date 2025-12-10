/**
 * @feature formBuilder
 */
component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		return renderFormControl(
			  argumentCollection = args
			, name               = controlName
			, type               = "textarea"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
			, defaultValue       = args.defaultvalue ?: ""
		);
	}

	private array function getValidationRules( event, rc, prc, args={} ) {
		var rules = [];

		if ( !IsNumeric( args.maxlength ?: "" ) ) {
			ArrayAppend( rules, { fieldname=args.name, validator="maxlength", params={ length=50000 } } );
		}

		return rules;
	}

	private string function renderV2ResponsesForDb( event, rc, prc, args={} ) {
		return args.response ?: "";
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		return "text";
	}
}