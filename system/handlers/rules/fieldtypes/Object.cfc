/**
 * Handler for rules engine 'object type'
 *
 * @feature rulesEngine
 */
component {

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

		var labels = [];
		for( var id in ids ){
			ArrayAppend( labels, renderLabel( objectName, id ) );
		}

		return arrayToList( labels, ", " );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var object        = config.object ?: "";
		var multiple      = IsTrue( config.multiple ?: true );
		var sortable      = IsTrue( config.sortable ?: true );
		var objectUriRoot = presideObjectService.getResourceBundleUriRoot( object );

		StructDelete( arguments.config, "disabledIfUnfiltered" );

		rc.delete( "value" );

		return renderFormControl(
			  argumentCollection = arguments.config
			, name               = "value"
			, type               = "objectPicker"
			, object             = object
			, multiple           = multiple
			, sortable           = sortable
			, label              = translateResource( objectUriRoot & "title" )
			, savedValue         = arguments.value
			, defaultValue       = arguments.value
			, required           = true
		);
	}

}