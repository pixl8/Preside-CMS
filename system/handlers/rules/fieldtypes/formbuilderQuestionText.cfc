/**
* Handler for rules engine to retrieve a select list of questions which are text
 *
 */
component {

	property name="formBuilderService"   inject="formBuilderService";
	property name="presideObjectService" inject="presideObjectService";

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

	private string function renderConfigScreen( string value="", struct config={} ) {
		var textQuestions = formBuilderService.getTextValueQuestions( );
		var values = [];
		var labels = [];
		var objectUriRoot = presideObjectService.getResourceBundleUriRoot( "formbuilder_question" );
		var label  = translateResource( objectUriRoot & "title" )

		for ( var question in textQuestions ) {
			arrayAppend( values, question.id );
			arrayAppend( labels, question.field_label );
		}

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