/**
 * Dynamic expression handler for checking whether or not a preside object
 * record matches one or more specific Ids
 *
 * @feature rulesEngine
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		,          string  value = ""
		,          boolean _is   = true
	) {
		return presideObjectService.dataExists(
			  objectName   = arguments.objectName
			, id           = payload[ arguments.objectName ].id ?: ""
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string  objectName
		,          string  value = ""
		,          boolean _is = true
	){
		var paramName = "recordMatchesId" & CreateUUId().lCase().replace( "-", "", "all" );
		var operator  = _is ? "in" : "not in";
		var filterSql = "#arguments.objectName#.id #operator# (:#paramName#)";
		var params    = { "#paramName#" = { value=arguments.value, type="cf_sql_varchar", list=true } };

		return [ { filter=filterSql, filterParams=params } ];
	}

	private string function getLabel(
		  required string  objectName
	) {
		var objectLabelSingular = translateObjectName( arguments.objectName );

		return translateResource( uri="rules.dynamicExpressions:recordMatchesId.label", data=[ objectLabelSingular ] );
	}

	private string function getText(
		  required string objectName

	){
		var objectLabelSingular = translateObjectName( arguments.objectName );

		return translateResource( uri="rules.dynamicExpressions:recordMatchesId.text", data=[ objectLabelSingular ] );
	}

}