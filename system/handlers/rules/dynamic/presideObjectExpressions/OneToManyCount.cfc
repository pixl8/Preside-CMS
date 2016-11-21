/**
 * Dynamic expression handler for checking the number
 * of records in a one-to-many relationship
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
		var subQuery = presideObjectService.selectData(
			  objectName          = arguments.objectName
			, selectFields        = [ "Count( #propertyName#.id ) onetomany_count", "#objectName#.id" ]
			, groupBy             = "#objectName#.id"
			, getSqlAndParamsOnly = true
		).sql;
		var subQueryAlias = "manyToManyCount" & CreateUUId().lCase().replace( "-", "", "all" );
		var paramName     = subQueryAlias;
		var filterSql     = "#subQueryAlias#.onetomany_count ${operator} :#paramName#";
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

		return [ { filter=filterSql, filterParams=params, extraJoins=[ {
			  type           = "left"
			, subQuery       = subQuery
			, subQueryAlias  = subQueryAlias
			, subQueryColumn = "id"
			, joinToTable    = arguments.objectName
			, joinToColumn   = "id"
		} ] } ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
		, required string  relationshipKey
	) {
		var relatedToBaseUri     = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var relatedPropertyTranslated = translateResource( relatedToBaseUri & "field.#relationshipKey#.title", relationshipKey );
		var relatedToTranslated  = translateResource( relatedToBaseUri & "title", relatedTo );

		return translateResource( uri="rules.dynamicExpressions:oneToManyCount.label", data=[ relatedToTranslated, relatedPropertyTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		, required string relatedTo
		, required string relationshipKey
	){
		var relatedToBaseUri          = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var relatedPropertyTranslated = translateResource( relatedToBaseUri & "field.#relationshipKey#.title", relationshipKey );
		var relatedToTranslated       = translateResource( relatedToBaseUri & "title", relatedTo );

		return translateResource( uri="rules.dynamicExpressions:oneToManyCount.text", data=[ relatedToTranslated, relatedPropertyTranslated ] );
	}

}