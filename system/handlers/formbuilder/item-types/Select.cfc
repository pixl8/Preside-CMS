component {

	private string function renderInput( event, rc, prc, args={} ) {
		var objectName      = args.datamanagerObject ?: "";
		var formControlArgs = Duplicate( args );

		formControlArgs.context                 = "formbuilder";
		formControlArgs.name                    = args.name ?: "";
		formControlArgs.id                      = args.id ?: formControlArgs.name;
		formControlArgs.layout                  = "";
		formControlArgs.required                = IsTrue( args.mandatory ?: "" );
		formControlArgs.multiple                = IsTrue( args.multiple  ?: "" );
		formControlArgs.class                   = "form-control";
		formControlArgs.removeObjectPickerClass = true;

		if( Len( Trim( objectName ) ) ) {
			formControlArgs.object = objectName;
			formControlArgs.type   = "objectPicker";
			formControlArgs.ajax   = false;
		} else {
			formControlArgs.type   = "select";
			formControlArgs.values = ListToArray( args.values, Chr( 10 ) & Chr( 13 ) );
			formControlArgs.labels = ListToArray( args.Labels, Chr( 10 ) & Chr( 13 ) );
		}

		return renderFormControl( argumentCollection = formControlArgs );
	}


	private string function renderResponse( event, rc, prc, args={} ) {
		var response = args.response ?: "";

		if ( isEmptyString( response ) ) {
			return "";
		}

		var itemConfig = args.itemConfiguration ?: {};
		var responses  = [];

		if ( !IsEmptyString( itemConfig.datamanagerObject ?: "" ) ) {
			responses = ListToArray( ReReplace( ( args.response ?: "" ), '^"(.*?)"$', "\1" ) );

			for ( var i=1; i<=ArrayLen( responses ); i++ ) {
				responses[ i ] = renderLabel( objectName=itemConfig.datamanagerObject, recordId=responses[ i ] );
			}
		} else {
			var values = ListToArray( itemConfig.values ?: "", Chr(10) & Chr(13) );
			var labels = ListToArray( itemConfig.labels ?: "", Chr(10) & Chr(13) );

			for ( var i=1; i<=ArrayLen( values ); i++ ) {
				if ( Find( values[ i ], response ) ) {
					ArrayAppend( responses, labels[ i ] ?: values[ i ] );
				}
			}
		}

		return ArrayToList( responses, args.delim ?: "<br>" );
	}

	private array function renderResponseForExport( event, rc, prc, args={} ) {
		args.delim = ", ";
		return [ renderResponse( argumentCollection=arguments ) ];
	}

	private array function renderV2ResponsesForDb( event, rc, prc, args={} ) {
		var response = args.response ?: "";

		if ( isEmptyString( response ) ) {
			return [];
		}

		var itemConfig = args.configuration ?: {};
		var responses  = [];

		if ( !IsEmptyString( itemConfig.datamanagerObject ?: "" ) ) {
			responses = ListToArray( response );
		} else {
			var values = ListToArray( itemConfig.values ?: "", Chr(10) & Chr(13) );

			for ( var value in values ) {
				if ( Find( value, response ) ) {
					ArrayAppend( responses, value );
				}
			}
		}

		return responses;
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		return "shorttext";
	}
}