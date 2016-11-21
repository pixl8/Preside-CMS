/**
 * Dynamic expression handler for checking the number
 * of records in a many-to-many relationship
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
		var paramName = "manyToManyCount" & CreateUUId().lCase().replace( "-", "", "all" );
		var filterSql = "Count( #propertyName#.id ) ${operator} :#paramName#";
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

		return [ { having=filterSql, filterParams=params } ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
	) {
		var objectBaseUri       = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToBaseUri    = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var objectName          = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated = translateResource( relatedToBaseUri & "title", relatedTo );

		return translateResource( uri="rules.dynamicExpressions:manyToManyCount.label", data=[ objectName, relatedToTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		, required string relatedTo
	){
		var objectBaseUri       = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToBaseUri    = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var objectName          = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated = translateResource( relatedToBaseUri & "title", relatedTo );

		return translateResource( uri="rules.dynamicExpressions:manyToManyCount.text", data=[ objectName, relatedToTranslated ] );
	}

}