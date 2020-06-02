/**
 * Handler for rules engine 'form builder field with multi choice values type'
 *
 */
component {

	property name="formBuilderService"   inject="formBuilderService";
	property name="presideObjectService" inject="presideObjectService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var formFieldId = config.fbformfield ?: ( rc.fbformfield ?: ( rc.fieldid ?: "" ) );
		var formField   = formBuilderService.getFormItem( formFieldId );
		var ids         = arguments.value.trim().listToArray();

		if ( !ids.len() ) {
			return config.defaultLabel ?: "";
		}

		if ( formField.count() ) {
			var sourceObject = formField.configuration.datamanagerObject ?: "";
			var values       = ( formField.configuration.values ?: "" ).listToArray( Chr( 10 ) & Chr( 13 ) );

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

			if ( values.len() ) {
				var labels  = _getLabels( formField.configuration );
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
		var formFieldId = config.fbformfield ?: ( rc.fbformfield ?: ( rc.fieldid ?: "" ) );

		rc.delete( "value" );

		var formField = formBuilderService.getFormItem( formFieldId );
		var label     = translateResource( "cms:rulesEngine.fieldtype.select.config.label" );

		if ( formField.count() ) {
			var sourceObject = formField.configuration.datamanagerObject ?: "";

			if ( Len( Trim( sourceObject ) ) ) {
				return renderFormControl(
					  argumentCollection = arguments.config
					, name               = "value"
					, type               = "objectPicker"
					, object             = sourceObject
					, multiple           = true
					, label              = label
					, savedValue         = arguments.value
					, defaultValue       = arguments.value
					, required           = true
				);
			}

			var values = ( formField.configuration.values ?: "" ).listToArray( Chr( 10 ) & Chr( 13 ) );
			if ( values.len() ) {
				var labels  = _getLabels( formField.configuration );

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
		}

		return '<p class="alert alert-warning"><i class="fa fa-fw fa-exclamation-triangle"></i> #translateResource( "cms:rulesEngine.fieldtype.formbuilderFieldMultiChoiceValue.no.choices.warning" )#</p>'
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