component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		event.include( assetId="/css/frontend/formbuilder/" );
		event.include( assetId="/css/frontend/formbuilder/datePicker/" );
		event.include( assetId="/js/frontend/formbuilder/datePicker/" );

		if ( Len( Trim( args.relativeOperator ?: "" ) ) && IsBoolean( args.relativeToCurrentDate ?: "" ) && args.relativeToCurrentDate ) {
			var theDate   = Now();
			var validator = "maximumDate";

			switch( args.relativeOperator ) {
				case "lt":
					var diff = val(args.offset) ? val(-args.offset) : -1;
					args.maxDate = DateAdd( 'd', diff, Now() );
				break;
				case "lte":
					args.maxDate = Now()
				break;
				case "gt":
					var diff = val(args.offset) ? val(args.offset) : 1;
					args.minDate = DateAdd( 'd', diff, Now() );
				break;
				case "gte":
					args.minDate = Now()
				break;
			}
		}

		return renderFormControl(
			  argumentCollection = args
			, name               = controlName
			, type               = "datepicker"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}

	private array function getValidationRules( event, rc, prc, args={} ) {
		var rules = [];


		rules.append( { fieldname=args.name, validator="date" } );

		if ( IsDate( args.minDate ?: "" ) ) {
			rules.append( { fieldname=args.name, validator="minimumDate", params={ minimumDate=args.minDate } } );
		}
		if ( IsDate( args.maxDate ?: "" ) ) {
			rules.append( { fieldname=args.name, validator="maximumDate", params={ maximumDate=args.maxDate } } );
		}

		if ( Len( Trim( args.relativeOperator ?: "" ) ) ) {
			if ( IsBoolean( args.relativeToCurrentDate ?: "" ) && args.relativeToCurrentDate ) {
				var theDate   = Now();
				var validator = "maximumDate";

				switch( args.relativeOperator ) {
					case "lt":
						theDate = DateAdd( 'd', -1, theDate );
					break;
					case "gt":
						theDate = DateAdd( 'd', 1, theDate );
					case "gte":
						validator = "minimumDate";
					break;
				}
				rules.append( { fieldname=args.name, validator=validator, params={ "#validator#"=DateFormat( theDate, "yyyy-mm-dd" ) } } );

			}
			if ( Len( Trim( args.relativeToField ?: "" ) ) ) {
				var validator = "";
				switch( args.relativeOperator ) {
					case "lt":
						validator = "earlierThanField";
					break;
					case "lte":
						validator = "earlierThanOrSameAsField";
					break;
					case "gt":
						validator = "laterThanField";
					break;
					case "gte":
						validator = "laterThanOrSameAsField";
					break;
				}

				rules.append( { fieldname=args.name, validator=validator, params={ field=args.relativeToField } } );
			}
		}
		return rules;
	}
}