/**
 * Dynamic expression handler for checking whether or not a preside object
 * numeric property's value matches compares to the given number input
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          string  _numericOperator = "eq"
		,          numeric value            = 0
	) {
		var recordId = payload[ objectName ].id ?: "";

		return presideObjectService.$dataExists(
			  objectName   = objectName
			, id           = recordId
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string  objectName
		, required string  propertyName
		,          string  _numericOperator = "eq"
		,          numeric value            = 0
	){
		var paramName = "numericPropertyCompares" & CreateUUId().lCase().replace( "-", "", "all" );
		var filterSql = "#objectName#.#propertyName# ${operator} :#paramName#";
		var params    = { "#paramName#" = { value=arguments.value, type="cf_sql_number" } };

		switch ( _numericOperator ) {
			case "eq":
				filterSql = filterSql.replace( "${operator}", "=" );
			break;
			case "neq":
				filterSql = filterSql.replace( "${operator}", "!=" );
			break;
			case "gt":
				filterSql = filterSql.replace( "${operator}", ">" );
			break;
			case "gte":
				filterSql = filterSql.replace( "${operator}", ">=" );
			break;
			case "lt":
				filterSql = filterSql.replace( "${operator}", "<" );
			break;
			case "lte":
				filterSql = filterSql.replace( "${operator}", "<=" );
			break;
		}

		return [ { filter=filterSql, filterParams=params } ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
	) {
		var objectBaseUri      = presideObjectService.getResourceBundleUriRoot( objectName );
		var propNameTranslated = translateResource( objectBaseUri & "field.#propertyName#.title", propertyName );

		return translateResource( uri="rules.dynamicExpressions:numericPropertyCompares.label", data=[ propNameTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
	){
		var objectBaseUri      = presideObjectService.getResourceBundleUriRoot( objectName );
		var propNameTranslated = translateResource( objectBaseUri & "field.#propertyName#.title", propertyName );

		return translateResource( uri="rules.dynamicExpressions:numericPropertyCompares.text", data=[ propNameTranslated ] );
	}

}