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
		return ArrayToList( _renderResponsesForView( argumentCollection=arguments, useLabel=true ), args.delim ?: "<br>" );
	}

	private array function renderResponseForExport( event, rc, prc, args={} ) {
		return [ ArrayToList( _renderResponsesForView( argumentCollection=arguments, useLabel=true ), ", " ) ];
	}

	private array function renderV2ResponsesForDb( event, rc, prc, args={} ) {
		return _renderResponsesForView( argumentCollection=arguments );
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		return "shorttext";
	}

	private array function _renderResponsesForView( event, rc, prc, args={}, boolean useLabel=false ) {
		var searchResponse = ",#args.response#,";

		if ( isEmptyString( searchResponse ) ) {
			return [];
		}

		var itemConfig     = args.itemConfiguration ?: ( args.configuration ?: {} );
		var matchResponses = [];

		var values = ListToArray( itemConfig.values ?: "", chr(13) & chr(10) );
		var labels = ListToArray( itemConfig.labels ?: "", chr(13) & chr(10) );

		for ( var i=1; i<=ArrayLen( values ); i++ ) {
			if ( Find( ",#values[ i ]#,", searchResponse ) ) {
				var renderResponse = useLabel ? ( labels[ i ] ?: values[ i ] ) : values[ i ];

				ArrayAppend( matchResponses, renderResponse );

				searchResponse = REReplace( Replace( searchResponse, ",#values[ i ]#,", "" ), "^,?(.*?),?$", ",\1," );
			}
		}

		return matchResponses;
	}

}