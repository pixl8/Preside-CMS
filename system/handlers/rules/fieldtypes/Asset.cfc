/**
 * Handler for rules engine 'asset' type
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var ids = value.trim().listToArray();

		if ( !ids.len() ) {
			return config.defaultLabel ?: "";
		}

		if ( ids.len() == 1 ) {
			return renderLabel( objectName="asset", recordId=ids[1] );
		}

		var records = presideObjectService.selectData(
			  objectName   = "asset"
			, selectFields = [ "${labelfield} as label" ]
			, filter       = { id=ids }
		);

		return ValueList( records.label, ", " );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var multiple      = IsTrue( config.multiple ?: true );
		var sortable      = IsTrue( config.sortable ?: true );

		return renderFormControl(
			  name         = "value"
			, type         = "assetPicker"
			, multiple     = multiple
			, sortable     = sortable
			, label        = translateResource( "cms:rulesEngine.fieldtype.asset.config.label" )
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, required     = true
		);
	}

}