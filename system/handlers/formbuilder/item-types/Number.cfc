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
			, class              = "number"
			, minValue           = Val( args.minValue ?: "" )
			, maxValue           = Val( args.maxValue ?: "" )
			, step               = Val( args.spinnerStep ?: 1 )
		);
	}

	private array function getValidationRules( event, rc, prc, args={} ) {
		var rules  = [];
		var format = args.format ?: "";

		switch( format ) {
			case "integer":
				rules.append( { fieldname=args.name, validator="digits" } );
				break;
			case "price":
				rules.append( { fieldname=args.name, validator="money" });
				break;
			default:
				rules.append( { fieldname=args.name, validator="number" } );
		}

		return rules;
	}

	private string function renderResponse( event, rc, prc, args={} ) {
		var number = args.response ?: "";

		if ( len( number ) ) {
			number = replace( number, """", "", "all" );

			if( isNumeric( number ) ) {
				return presideStandardNumberFormat( val( number ) );
			}
		}

		return "";
	}

	private string function renderV2ResponsesForDb( event, rc, prc, args={} ) {
		if ( Len( args.response ?: "" ) ) {
			return Val( Replace( args.response, ",", "", "all" ) );
		}

		return "";
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		var format = args.configuration.format ?: "";

		if ( format == "integer" ) {
			return "int";
		}

		return "float";
	}
}