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
		return ArrayToList( _renderResponsesForView( argumentCollection=arguments ), args.delim ?: "<br>" );
	}

	private array function renderResponseForExport( event, rc, prc, args={} ) {
		return [ ArrayToList( _renderResponsesForView( argumentCollection=arguments ), ", " ) ];
	}

	private array function renderV2ResponsesForDb( event, rc, prc, args={} ) {
		var searchResponse = ",#args.response#,";

		if ( isEmptyString( searchResponse ) ) {
			return [];
		}

		var itemConfig     = args.configuration ?: {};
		var matchResponses = [];

		var values = ListToArray( itemConfig.values ?: "", Chr(10) & Chr(13) );

		for ( var value in values ) {
			if ( Find( ",#value#,", searchResponse ) ) {
				ArrayAppend( matchResponses, value );
			}
		}

		return matchResponses;
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		return "shorttext";
	}

	private array function _renderResponsesForView( event, rc, prc, args={} ) {
		var searchResponse = ",#args.response#,";

		if ( isEmptyString( searchResponse ) ) {
			return [];
		}

		var itemConfig     = args.itemConfiguration ?: {};
		var matchResponses = [];

		var values = ListToArray( itemConfig.values, chr(13) & chr(10) );
		var labels = ListToArray( itemConfig.labels, chr(13) & chr(10) );

		for ( var i=1; i<=ArrayLen( values ); i++ ) {
			if ( Find( ",#values[ i ]#,", searchResponse ) ) {
				ArrayAppend( matchResponses, labels[ i ] ?: values[ i ] );
			}
		}

		return matchResponses;
	}

}