component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";
		event.include( assetId="/css/frontend/formbuilder/" );
		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "number"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
			, step               = 0.01
			, class              = "price"
		);
	}

	private string function renderResponse( event, rc, prc, args={} ) {
		price =  args.response&' '&args.itemConfiguration.currency;
		return price;
	}

	private array function getValidationRules( event, rc, prc, args={} ) {
        var rules = [];
        rules.append({ fieldname=args.name, validator="currency" });
        return rules;
    }
}