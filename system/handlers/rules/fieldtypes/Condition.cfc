/**
 * Handler for rules engine 'boolean type'
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
		var multiple = IsTrue( config.multiple ?: true );
		var sortable = IsTrue( config.sortable ?: true );

		return renderFormControl(
			  name         = "value"
			, type         = "conditionPicker"
			, multiple     = multiple
			, sortable     = sortable
			, ruleContext  = rc.context ?: "global"
			, label        = translateResource( "cms:rulesEngine.fieldtype.condition.config.label" )
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, required     = true
		);
	}

}