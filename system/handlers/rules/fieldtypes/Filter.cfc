/**
 * Handler for rules engine 'filter' type
 *
 */
component {

	property name="rulesEngineConditionService" inject="rulesEngineConditionService";
	property name="presideObjectService"        inject="presideObjectService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var ids = ListToArray( Trim( value ) );

		if ( !ids.len() ) {
			return config.defaultLabel ?: "";
		}

		if ( ids.len() == 1 ) {
			return renderLabel( objectName="rules_engine_condition", recordId=ids[1] );
		}

		var records = presideObjectService.selectData(
			  objectName   = "rules_engine_condition"
			, selectFields = [ "${labelfield} as label" ]
			, filter       = { id=ids }
		);
		return ValueList( records.label, ", " );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var multiple  = IsTrue( config.multiple  ?: true );
		var sortable  = IsTrue( config.sortable  ?: true );
		var quickadd  = IsTrue( config.quickAdd  ?: true );
		var quickEdit = IsTrue( config.quickEdit ?: true );

		rc.delete( "value" );

		return renderFormControl(
			  name         = "value"
			, type         = "filterPicker"
			, multiple     = multiple
			, sortable     = sortable
			, quickadd     = true
			, quickEdit    = true
			, filterObject = rc.object ?: "global"
			, label        = translateResource( "cms:rulesEngine.fieldtype.filter.config.label" )
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, required     = true
		);
	}

}