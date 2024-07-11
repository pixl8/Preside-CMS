/**
 * @feature formBuilder
 */
component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		if ( Len( Trim( args.relativeOperator ?: "" ) ) && IsBoolean( args.relativeToCurrentTime ?: "" ) && args.relativeToCurrentTime ) {
			var theDate   = Now();
			var validator = "maximumTime";
			

			switch( args.relativeOperator ) {
				case "lt":
					var diff = val(args.offset) ? val(-args.offset) : -1;
					args.maxTime = datetimeformat(DateAdd( 'n', diff, Now() ),"HH:nn");
				break;
				case "lte":
					var diff = val(args.offset) ? val(-args.offset) : 0;
					args.maxTime = datetimeformat(DateAdd( 'n', diff, Now() ),"HH:nn");
				break;
				case "gt":
					var diff = val(args.offset) ? val(args.offset) : 1;
					args.minTime = datetimeformat(DateAdd( 'n', diff, Now() ),"HH:nn");
				break;
				case "gte":
					var diff = val(args.offset) ? val(args.offset) : 0;
					args.minTime = datetimeformat(DateAdd( 'n', diff, Now() ),"HH:nn");
				break;
			}
		}
		
		return renderFormControl(
			  argumentCollection = args
			, name               = controlName
			, type               = "timepicker"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}

	private array function getValidationRules( event, rc, prc, args={} ) {
		var rules = [];

		if ( IsDate( args.minTime ?: "" ) ) {
			rules.append( { fieldname=args.name, validator="minimumTime", params={ minimumTime=args.minTime } } );
		}
		if ( IsDate( args.maxTime ?: "" ) ) {
			rules.append( { fieldname=args.name, validator="maximumTime", params={ maximumTime=args.maxTime } } );
		}
		if ( Len( Trim( args.relativeOperator ?: "" ) ) ) {
			if ( IsBoolean( args.relativeToCurrentTime ?: "" ) && args.relativeToCurrentTime ) {
				var theTime   = Now();
				var validator = "maximumTime";
				
				switch( args.relativeOperator ) {
					case "lt":
					theTime = datetimeformat( DateAdd( 'n', -1, theTime ) ,"HH:nn");
					break;
					case "gt":
					theTime = datetimeformat( DateAdd( 'n', 1, theTime ) ,"HH:nn");
					case "gte":
					validator = "minimumTime";
					break;
				}
				rules.append( { fieldname=args.name, validator=validator, params={ "#validator#"=DateTimeFormat( theTime, "hh:nn tt" ) } } );
				
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
	
	private string function renderV2ResponsesForDb( event, rc, prc, args={} ) {
		return IsDate( args.response ?: "" ) ? args.response : "";
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		return "date";
	}
}