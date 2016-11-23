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
		,          string  filterPrefix = ""
		,          string  _numericOperator = "eq"
		,          numeric value            = 0
	){
		var subQuery = presideObjectService.selectData(
			  objectName          = arguments.objectName
			, selectFields        = [ "Count( #propertyName#.id ) manytomany_count", "#objectName#.id" ]
			, groupBy             = "#objectName#.id"
			, getSqlAndParamsOnly = true
		).sql;
		var subQueryAlias = "manyToManyCount" & CreateUUId().lCase().replace( "-", "", "all" );
		var paramName     = subQueryAlias;
		var filterSql     = "#subQueryAlias#.manytomany_count ${operator} :#paramName#";
		var params        = { "#paramName#" = { value=arguments.value, type="cf_sql_number" } };

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

		var prefix = filterPrefix.len() ? filterPrefix : objectName;

		return [ { filter=filterSql, filterParams=params, extraJoins=[ {
			  type           = "left"
			, subQuery       = subQuery
			, subQueryAlias  = subQueryAlias
			, subQueryColumn = "id"
			, joinToTable    = prefix
			, joinToColumn   = "id"
		} ] } ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
	) {
		var objectBaseUri        = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToBaseUri     = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var objectNameTranslated = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated  = translateResource( relatedToBaseUri & "title", relatedTo );

		return translateResource( uri="rules.dynamicExpressions:manyToManyCount.label", data=[ objectNameTranslated, relatedToTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		, required string relatedTo
	){
		var objectBaseUri        = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToBaseUri     = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var objectNameTranslated = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated  = translateResource( relatedToBaseUri & "title", relatedTo );

		return translateResource( uri="rules.dynamicExpressions:manyToManyCount.text", data=[ objectNameTranslated, relatedToTranslated ] );
	}

}