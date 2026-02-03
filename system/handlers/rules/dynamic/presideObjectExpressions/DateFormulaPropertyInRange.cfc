/**
 * Dynamic expression handler for checking whether or not a preside object
 * formula property value is within a given date range
 *
 * @feature rulesEngine
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService"     inject="presideObjectService";
	property name="rulesEngineFilterService" inject="rulesEngineFilterService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          struct  _time
	) {
		return presideObjectService.dataExists(
			  objectName   = arguments.objectName
			, id           = payload[ arguments.objectName ].id ?: ""
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string  objectName
		, required string  propertyName
		,          struct  _time = {}
	){
		var suffix  = CreateUUId().lCase().replace( "-", "", "all" )
		var params  = {};
		var filter  = "";
		var delim   = "";

		if ( IsDate( _time.from ?: "" ) ) {
			var fromParam = "dateFormulaPropertyFrom" & suffix;
			filter   = "#arguments.propertyName# >= :#fromParam#";
			params[ fromParam ] = { value=_time.from, type="cf_sql_timestamp" };
			delim = " and ";
		}
		if ( IsDate( _time.to ?: "" ) ) {
			var toParam = "dateFormulaPropertyTo" & suffix;
			filter   &= delim & "#arguments.propertyName# <= :#toParam#";
			params[ toParam ] = { value=_time.to, type="cf_sql_timestamp" };
		}

		if ( Len( filter ) ) {
			return [ rulesEngineFilterService.prepareAutoFormulaFilter(
				  objectName   = arguments.objectName
				, propertyName = arguments.propertyName
				, filter       = filter
				, filterParams = params
			) ];
		}

		return [];
	}

	private string function getLabel(
		  required string objectName
		, required string propertyName
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	) {
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.dateFormulaPropertyInRange.label", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:dateFormulaPropertyInRange.label", data=[ propNameTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	){
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.dateFormulaPropertyInRange.text", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:dateFormulaPropertyInRange.text", data=[ propNameTranslated ] );
	}
}