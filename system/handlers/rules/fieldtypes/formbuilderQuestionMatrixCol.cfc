/**
 * Handler for rules engine to retrieve a select list of columns for a matrix question
 *
 */
component {

	property name="formBuilderService"   inject="formBuilderService";
	property name="presideObjectService" inject="presideObjectService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var questionId = config.question ?: ( rc.fbformfield ?: ( rc.fieldid ?: "" ) );
		var theQuestion  = formBuilderService.getQuestion( questionId );
		var ids         = arguments.value.trim().listToArray();

		if ( !ids.len() ) {
			return config.defaultLabel ?: "";
		}

		if ( len( theQuestion ) ) {
			var questionConfig = DeserializeJson( theQuestion.item_type_config );
			var values  = ListToArray( questionConfig.values ?: "", Chr( 10 ) & Chr( 13 ) );
			if ( values.len() ) {
				var labels  = _getLabels( questionConfig );
				var items   = [];

				for( var id in ids ) {
					var index = values.findNoCase( id );
					if ( index ) {
						items.append( labels[ index ] ?: values[ index ] );
					}
				}

				return items.toList( ", " );
			}
		}

		return arguments.value;
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var questionId = config.question ?: ( rc.question ?: "" );

		rc.delete( "value" );

		var theQuestion = formBuilderService.getQuestion( questionId );
		var label     = translateResource( "cms:rulesEngine.fieldtype.select.config.label" );


		if ( len( theQuestion ) ) {
			var questionConfig = DeserializeJson( theQuestion.item_type_config );
			var columns  = ListToArray( questionConfig.columns ?: "", Chr( 10 ) & Chr( 13 ) );
			if ( columns.len() ) {
				return renderFormControl(
					  argumentCollection = arguments.config
					, name               = "value"
					, type               = "select"
					, values             = columns
					, labels             = columns
					, multiple           = true
					, label              = label
					, savedValue         = arguments.value
					, defaultValue       = arguments.value
					, required           = true
				);
			}
		}

		return '<p class="alert alert-warning"><i class="fa fa-fw fa-exclamation-triangle"></i> #translateResource( "cms:rulesEngine.fieldtype.formbuilderQuestionMatrixCol.no.choices.warning" )#</p>'
	}


}