component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "matrix"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
			, rows               = replaceNoCase( args.rows, chr( 10 ), ',', 'All' )	?: "" // chr ( 10 ) means newline
			, columns			 = replaceNoCase( args.columns, chr( 10 ), ',', 'All' )	?: ""
		);
	}

	private any function getItemDataFromRequest( event, rc, prc, args={} ) {
		var inputName   = args.inputName ?: "";
		var itemConfig  = args.itemConfiguration ?: {};
		var rows        = ListToArray( itemConfig.rows ?: "", Chr(10) & Chr(13) );
		var isMandatory = IsTrue( itemConfig.mandatory ?: "" );
		var data        = {};

		for( var i=1; i <= rows.len(); i++ ) {
			if ( Len( Trim( rows[ i ] ) ) ) {
				var expectedInputName = inputName & "_" & rows[i];
				var value             = rc[ expectedInputName ] ?: "";

				if ( isMandatory && !Len( Trim( value ) ) ) {
					return "";
				}

				data[ rows[ i ] ] = value;
			}
		}

		return SerializeJson( data );
	}

	private string function renderResponse( event, rc, prc, args={} ) {
		var qAndA = _getQuestionsAndAnswers( argumentCollection=arguments );

		return renderView( view="/formbuilder/item-types/matrix/renderResponse", args={ answers=qAndA } );
	}

	private array function renderResponseForExport( event, rc, prc, args={} ) {
		var qAndA = _getQuestionsAndAnswers( argumentCollection=arguments );
		var justAnswers = [];

		for( qa in qAndA ) {
			justAnswers.append( qa.answer );
		}

		return justAnswers;
	}

	private array function getExportColumns( event, rc, prc, args={} ) {
		var rows       = ListToArray( args.rows ?: "", Chr(10) & Chr(13) );
		var columns    = [];
		var itemName   = args.label ?: "";

		for( var row in rows ) {
			if ( !IsEmpty( Trim( row ) ) ) {
				columns.append( itemName & ": " & row );
			}
		}

		return columns;
	}

// private helpers
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