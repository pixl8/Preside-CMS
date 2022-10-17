/**
 * Handler for rules engine to retrieve a Question picker
 *
 */
component {
	property name="presideObjectService" inject="presideObjectService";
	property name="formBuilderService"   inject="formBuilderService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var objectName = "formbuilder_form";
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
		var object        = "formbuilder_form";
		var objectUriRoot = presideObjectService.getResourceBundleUriRoot( object );
		var filterBy      = "question";
		var filterByField = "items.question";

		rc.delete( "value" );

		return renderFormControl(
			  argumentCollection = arguments.config
			, name               = "value"
			, type               = "objectPicker"
			, object             = object
			, filterBy           = filterBy
			, filterByField      = filterByField
			, multiple           = false
			, sortable           = false
			, label              = translateResource( objectUriRoot & "title" )
			, savedValue         = arguments.value
			, defaultValue       = arguments.value
			, required           = true
		);
	}
}