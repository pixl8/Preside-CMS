/**
 * Handler for rules engine to retrieve a select list of values for a multi-choice question
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
			var sourceObject = questionConfig.datamanagerObject?:"";
			if ( Len( Trim( sourceObject ) ) ) {
				if ( ids.len() == 1 ) {
					return renderLabel( objectName=sourceObject, recordId=ids[1] );
				}

				var records = presideObjectService.selectData(
					  objectName   = sourceObject
					, selectFields = [ "${labelfield} as label" ]
					, filter       = { id=ids }
				);
				return ValueList( records.label, ", " );
			}

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
			var labels  = _getLabels( questionConfig );
			var values  = ListToArray( questionConfig.values ?: "", Chr( 10 ) & Chr( 13 ) );
			if ( values.len() ) {
				return renderFormControl(
					  argumentCollection = arguments.config
					, name               = "value"
					, type               = "select"
					, values             = values
					, labels             = labels
					, multiple           = true
					, label              = label
					, savedValue         = arguments.value
					, defaultValue       = arguments.value
					, required           = true
				);
			}

			var dataManagerObject = questionConfig.datamanagerObject?:"";
			if ( len( datamanagerObject) ) {
				return renderFormControl(
					  argumentCollection = arguments.config
					, name               = "value"
					, type               = "objectPicker"
					, object             = dataManagerObject
					, multiple           = true
					, label              = label
					, savedValue         = arguments.value
					, defaultValue       = arguments.value
					, required           = true
				);
			}

		}

		return '<p class="alert alert-warning"><i class="fa fa-fw fa-exclamation-triangle"></i> #translateResource( "cms:rulesEngine.fieldtype.formbuilderQuestionMultiChoiceValue.no.choices.warning" )#</p>'
	}

	// helpers
	private array function _getLabels( config ) {
		var values        = ListToArray( config.values ?: "", Chr( 10 ) & Chr( 13 ) );
		var labels        = ListToArray( config.labels ?: "", Chr( 10 ) & Chr( 13 ) );
		var labelUriRoot  = config.labelUriRoot ?: "";

		if ( values.len() && !labels.len() ) {
			if ( labelUriRoot.len() ) {
				for( var value in values ) {
					labels.append( translateResource( labelUriRoot & value ) );
				}
			} else {
				labels = values;
			}
		}

		return labels;
	}


}