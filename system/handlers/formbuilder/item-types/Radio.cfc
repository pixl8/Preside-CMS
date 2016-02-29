component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "radio"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
			, values             = ListToArray( args.values ?: "", Chr(10) & Chr(13) )
			, labels             = ListToArray( args.labels ?: "", Chr(10) & Chr(13) )
		);
	}

	private string function renderResponse( event, rc, prc, args={} ) {
		var itemConfig = args.itemConfiguration ?: {};
		var response   = args.response;
		var values     = ListToArray( itemConfig.values ?: "", Chr( 10 ) & Chr( 13 ) );
		var labels     = ListToArray( itemConfig.labels ?: "", Chr( 10 ) & Chr( 13 ) );

		for( var i=1; i<=values.len(); i++ ) {
			if ( values[ i ] == response ) {
				if ( labels.len() >= i && labels[ i ] != values[ i ] ) {
					return labels[ i ] & " (#values[i]#)";
				}
				return response;
			}
		}

		return response;
	}

	private array function renderResponseForExport( event, rc, prc, args={} ) {
		return [ renderResponse( argumentCollection=arguments ) ];
	}

	private array function _getQuestionsAndAnswers( event, rc, prc, args={} ) {
		var response   = IsJson( args.response ?: "" ) ? DeserializeJson( args.response ) : {};
		var itemConfig = args.itemConfiguration ?: {};
		var rows       = ListToArray( itemConfig.rows ?: "", Chr(10) & Chr(13) );
		var answers    = [];

		for( var i=1; i <= rows.len(); i++ ) {

			if ( Len( Trim( rows[ i ] ) ) ) {
				answers.append( {
					  question = rows[i]
					, answer   = ListChangeDelims( ( response[ rows[i] ] ?: "" ), ", " )
				} );
			}
		}

		return answers;
	}
}