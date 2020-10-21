/**
 * Handler for rules engine to retrieve a Question picker
 *
 */
component {
	property name="presideObjectService" inject="presideObjectService";
	property name="formBuilderService"   inject="formBuilderService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var objectName = config.object ?: "";
		var ids        = ListToArray( Trim( value ) );

		if ( !ids.len() ) {
			return config.defaultLabel ?: "";
		}

		if ( ids.len() == 1 ) {
			return renderLabel( objectName=objectName, recordId=ids[1] );
		}

		var records = presideObjectService.selectData(
			  objectName   = objectName
			, selectFields = [ "${labelfield} as label" ]
			, filter       = { id=ids }
		);
		return ValueList( records.label, ", " );
	}

	private string function renderConfigScreen( string value="", string item_type="", struct config={} ) {
		var questions = formBuilderService.getQuestions( item_type=config.item_type, formId=config.formId?:"" );
		var values = [];
		var labels = [];
		var objectUriRoot = presideObjectService.getResourceBundleUriRoot( "formbuilder_question" );
		var label  = translateResource( objectUriRoot & "title" )

		for ( var question in questions ) {
			arrayAppend( values, question.id );
			arrayAppend( labels, question.field_label );
		}

		if ( values.len() ) {
			return renderFormControl(
				  argumentCollection = arguments.config
				, name               = "value"
				, type               = "select"
				, values             = values
				, labels             = labels
				, multiple           = false
				, label              = label
				, savedValue         = arguments.value
				, defaultValue       = arguments.value
				, value              = arguments.value
				, required           = true
			);
		}
	}
}