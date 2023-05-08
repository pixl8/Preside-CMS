component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		return renderFormControl(
			  argumentCollection = args
			, name               = controlName
			, type               = "checkboxList"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
			, values             = ListToArray( args.values ?: "", Chr(10) & Chr(13) )
			, labels             = ListToArray( args.labels ?: "", Chr(10) & Chr(13) )
		);
	}

	private string function renderResponse( event, rc, prc, args={} ) {
		return ArrayToList( _renderResponses( argumentCollection=arguments ), args.delim ?: "<br>" );
	}

	private array function renderResponseForExport( event, rc, prc, args={} ) {
		return [ ArrayToList( _renderResponses( argumentCollection=arguments ), ", " ) ];
	}

	private array function renderV2ResponsesForDb( event, rc, prc, args={} ) {
		var response = args.response ?: "";

		if ( isEmptyString( response ) ) {
			return [];
		}

		var itemConfig = args.configuration ?: {};
		var responses = [];

		var values = ListToArray( itemConfig.values ?: "", Chr(10) & Chr(13) );

		for ( var value in values ) {
			if ( Find( value, response ) ) {
				ArrayAppend( responses, value );
			}
		}

		return responses;
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		return "shorttext";
	}

	private array function _renderResponses( event, rc, prc, args={} ) {
		var response = args.response ?: "";

		if ( isEmptyString( response ) ) {
			return [];
		}

		var itemConfig = args.itemConfiguration ?: {};
		var responses  = [];

		var values = ListToArray( itemConfig.values, chr(13) & chr(10) );
		var labels = ListToArray( itemConfig.labels, chr(13) & chr(10) );

		for ( var i=1; i<=ArrayLen( values ); i++ ) {
			if ( Find( values[ i ], response ) ) {
				ArrayAppend( responses, labels[ i ] ?: values[ i ] );
			}
		}

		return responses;
	}

}