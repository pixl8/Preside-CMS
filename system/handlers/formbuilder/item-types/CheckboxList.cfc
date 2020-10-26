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
		var responses = ListToArray( args.response );
		var values    = ListToArray( args.itemConfiguration.values, chr(13) & chr(10) );
		var labels    = ListToArray( args.itemConfiguration.labels, chr(13) & chr(10) );

		var renderLabels = [];
		for ( var response in responses ) {
			var ix = values.find( response );
			if ( ix>0 ) {
				renderLabels.append( labels[ix] );
			}
		}

		return ArrayToList( renderLabels, ", " );
	}

	private array function renderResponseForExport( event, rc, prc, args={} ) {
		var responses = ListToArray( args.response.replace( """", "", "all") );
		var values    = ListToArray( args.itemConfiguration.values, chr(13) & chr(10) );
		var labels    = ListToArray( args.itemConfiguration.labels, chr(13) & chr(10) );
		var renderLabels = [];
		for ( var response in responses ) {
			var ix = values.find( response );
			if ( ix>0 ) {
				renderLabels.append( labels[ix] );
			}
		}
		return [ ArrayToList( renderLabels, ", " ) ];
	}

	private array function renderV2ResponsesForDb( event, rc, prc, args={} ) {

		return ListToArray( args.response ?: "" );
	}

	private string function getQuestionDataType( event, rc, prc, args={} ) {
		return "shorttext";
	}
}