/**
 * Dynamic expression handler for checking whether or not a preside object
 * boolean formula property's value is true / fase
 *
 * @feature rulesEngine
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService"     inject="presideObjectService";
	property name="rulesEngineFilterService" inject="rulesEngineFilterService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          boolean _is = true
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
		,          boolean _is = true
	){
		var paramName = "booleanFormulaPropertyIsTrue" & CreateUUId().lCase().replace( "-", "", "all" );

		return [ rulesEngineFilterService.prepareAutoFormulaFilter(
			  objectName   = arguments.objectName
			, propertyName = arguments.propertyName
			, filter       = "#arguments.propertyName# = :#paramName#"
			, filterParams = { "#paramName#" ={ type="cf_sql_boolean", value=arguments._is }}
		) ];
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
			return translateResource( uri="rules.dynamicExpressions:related.booleanFormulaPropertyIsTrue.label", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:booleanFormulaPropertyIsTrue.label", data=[ propNameTranslated ] );
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
			return translateResource( uri="rules.dynamicExpressions:related.booleanFormulaPropertyIsTrue.text", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:booleanFormulaPropertyIsTrue.text", data=[ propNameTranslated ] );
	}

}