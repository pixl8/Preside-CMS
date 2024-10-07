/**
 * @feature formBuilder
 */
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
		formControlArgs.includeEmptyOption      = IsTrue( args.includeEmptyOption  ?: "" );
		formControlArgs.class                   = "form-control";
		formControlArgs.removeObjectPickerClass = true;

		if( Len( Trim( objectName ) ) ) {
			formControlArgs.object = objectName;
			formControlArgs.type   = "objectPicker";
			formControlArgs.ajax   = false;
		} else {
			formControlArgs.type         = "select";
			formControlArgs.values       = ListToArray( args.values, Chr( 10 ) & Chr( 13 ) );
			formControlArgs.labels       = ListToArray( args.Labels, Chr( 10 ) & Chr( 13 ) );
			formControlArgs.defaultValue = args.defaultvalue ?: "";
		}

		return renderFormControl( argumentCollection = formControlArgs );
	}

	private string function renderResponse( event, rc, prc, args={} ) {
		return ArrayToList( _renderResponses( argumentCollection=arguments, useLabel=true ), args.delim ?: "<br>" );
	}

	private array function renderResponseForExport( event, rc, prc, args={} ) {
		args.delim = ", ";
		return [ renderResponse( argumentCollection=arguments ) ];
	}

	private array function renderV2ResponsesForDb( event, rc, prc, args={} ) {
		return _renderResponses( argumentCollection=arguments );
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		return "shorttext";
	}

	private array function _renderResponses( event, rc, prc, args={}, boolean useLabel=false ) {
		if ( isEmptyString( args.response ?: "" ) ) {
			return [];
		}

		var itemConfig     = args.itemConfiguration ?: ( args.configuration ?: {} );
		var matchResponses = [];

		if ( !IsEmptyString( itemConfig.datamanagerObject ?: "" ) ) {
			if ( useLabel ) {
				matchResponses = ListToArray( ReReplace( args.response, '^"(.*?)"$', "\1" ) );

				for ( var i=1; i<=ArrayLen( matchResponses ); i++ ) {
					matchResponses[ i ] = renderLabel( objectName=itemConfig.datamanagerObject, recordId=matchResponses[ i ] );
				}
			} else {
				matchResponses = ListToArray( args.response );
			}
		} else {
			var searchResponse = ",#args.response#,";

			var values = ListToArray( itemConfig.values ?: "", chr(13) & chr(10) );
			var labels = ListToArray( itemConfig.labels ?: "", chr(13) & chr(10) );

			for ( var i=1; i<=ArrayLen( values ); i++ ) {
				if ( Find( ",#values[ i ]#,", searchResponse ) ) {
					var renderResponse = useLabel ? ( labels[ i ] ?: values[ i ] ) : values[ i ];

					ArrayAppend( matchResponses, renderResponse );

					searchResponse = Replace( searchResponse, ",#values[ i ]#,", "," );
				}
			}
		}

		return matchResponses;
	}

}