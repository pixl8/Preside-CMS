/**
 * Dynamic expression handler for checking whether or not a preside object
 * enum property's value matches the supplied enum option
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          boolean _is       = true
		,          string  enumValue = ""
	) {
		var recordId = payload[ objectName ].id ?: "";

		return presideObjectService.dataExists(
			  objectName   = objectName
			, id           = recordId
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string  objectName
		, required string  propertyName
		,          string  filterPrefix = ""
		,          boolean _is          = true
		,          string  enumValue    = ""
	){
		var prefix    = filterPrefix.len() ? filterPrefix : objectName;
		var paramName = "textPropertyMatches" & CreateUUId().lCase().replace( "-", "", "all" );
		var filterSql = "#prefix#.#propertyName# ${operator} (:#paramName#)";
		var params    = { "#paramName#" = { value=arguments.enumValue, type="cf_sql_varchar", list=true } };

		if ( _is ) {
			filterSql = filterSql.replace( "${operator}", "in" );
		} else {
			filterSql = filterSql.replace( "${operator}", "not in" );
		}

		return [ { filter=filterSql, filterParams=params } ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
	) {
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		return translateResource( uri="rules.dynamicExpressions:enumPropertyMatches.label", data=[ propNameTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
	){
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		return translateResource( uri="rules.dynamicExpressions:enumPropertyMatches.text", data=[ propNameTranslated ] );
	}

}