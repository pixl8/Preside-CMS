component {

	private string function renderInput( event, rc, prc, args={} ) {
		var rows             = ListToArray( args.rows    ?: "", Chr( 10 ) & Chr( 13 ) );
		var columns          = ListToArray( args.columns ?: "", Chr( 10 ) & Chr( 13 ) );
		var questionInputIds = [];
		var inputName        = args.name ?: "";

		for( var question in rows ) {
			questionInputIds.append( _getQuestionInputId( inputName, question ) );
		}

		return renderFormControl(
			  argumentCollection = args
			, type               = "matrix"
			, context            = "formbuilder"
			, id                 = args.id ?: ( args.name ?: "" )
			, layout             = ""
			, required           = IsTrue( args.mandatory    ?: "" )
			, rows               = rows
			, columns            = columns
			, questionInputIds   = questionInputIds
		);
	}

	private string function getItemDataFromRequest( event, rc, prc, args={} ) {
		var inputName   = args.inputName         ?: "";
		var itemConfig  = args.itemConfiguration ?: {};
		var formFields  = getFormFields( event, rc, prc, itemConfig );
		var rows        = ListToArray( itemConfig.rows ?: "", Chr(10) & Chr(13) );
		var isMandatory = IsTrue( itemConfig.mandatory ?: "" );
		var data        = {};

		for( var field in formFields ) {
			data[ field ] = rc[ field ] ?: "";

			if( isMandatory && !Len( Trim( data[ field ] ) ) ) {
				return "";
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

		for( var qa in qAndA ) {
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

	private array function getFormFields( event, rc, prc, args={} ) {
		var inputName = args.name ?: "";
		var rows      = ListToArray( Trim( args.rows ?: "" ), Chr(10) & Chr(13) );
		var fields    = [];

		for( var question in rows ) {
			if ( Len( Trim( question ) ) ) {
				fields.append( _getQuestionInputId( inputName, question ) );
			}
		}

		return fields;
	}

// private helpers
	private array function _getQuestionsAndAnswers( event, rc, prc, args={} ) {
		var response   = IsJson( args.response ?: "" ) ? DeserializeJson( args.response ) : {};
		var itemConfig = args.itemConfiguration ?: {};
		var rows       = ListToArray( Trim( itemConfig.rows ?: "" ), Chr(10) & Chr(13) );
		var answers    = [];

		for( var question in rows ) {
			if ( Len( Trim( question ) ) ) {
				var inputId = _getQuestionInputId( itemConfig.name ?: "", question );

				answers.append( {
					  question = question
					, answer   = ListChangeDelims( ( response[ inputId ] ?: "" ), ", " )
				} );
			}
		}

		return answers;
	}

	private string function _getQuestionInputId( required string inputName, required string question ) {
		return LCase( inputName & "-" & ReReplace( question, "\W", "-", "all" ) );
	}
}