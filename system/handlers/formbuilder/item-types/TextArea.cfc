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
		var rules     = [];
		var maxlength = args.maxlength ?: "";

		if ( !IsNumeric( maxlength ) || ( Val( maxlength ) <= 0 ) ) {
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