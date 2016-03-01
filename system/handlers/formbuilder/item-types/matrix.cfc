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

	private array function getValidationRules( event, rc, prc, args={} ) {
		var rules     = [];
		var inputName = args.name ?: "";

		if ( IsBoolean( args.mandatory ?: "" ) && args.mandatory ) {
			var rows = ListToArray( Trim( args.rows ?: "" ), Chr(10) & Chr(13) );

			for( var question in rows ) {
				if ( Len( Trim( question ) ) ) {
					rules.append( {
						  fieldname = _getQuestionInputId( inputName, question )
						, validator = "required"
					} );
				}
			}
		}

		return rules;
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
				answers.append( {
					  question = question
					, answer   = ListChangeDelims( ( response[ question ] ?: "" ), ", " )
				} );
			}
		}

		return answers;
	}

	private string function _getQuestionInputId( required string inputName, required string question ) {
		return LCase( inputName & "-" & ReReplace( question, "\W", "-", "all" ) );
	}
}