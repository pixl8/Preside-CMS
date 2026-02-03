/**
 * @feature formBuilder
 *
 */
component {
	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		return renderFormControl(
			  argumentCollection = args
			, name               = controlName
			, type               = "urlInput"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
		);
	}

	private string function renderV2ResponsesForDb( event, rc, prc, args={} ) {
		return args.response ?: "";
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		return "text";
	}

	private array function getValidationRules( event, rc, prc, args={} ) {
		return [ { fieldname=args.name, validator="url" } ];
	}
}