/**
 * Dynamic expression handler for checking whether or not a preside object
 * numeric property's value matches compares to the given number input
 *
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          string  _numericOperator = "eq"
		,          numeric value            = 0
	) {
		var sourceObject = parentObjectName.len() ? parentObjectName : objectName;
		var recordId     = payload[ sourceObject ].id ?: "";

		return presideObjectService.dataExists(
			  objectName   = sourceObject
			, id           = recordId
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string  objectName
		, required string  propertyName
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          string  filterPrefix = ""
		,          string  _numericOperator = "eq"
		,          numeric value            = 0
	){
		var paramName = "numericFormulaPropertyCompares" & CreateUUId().lCase().replace( "-", "", "all" );
		var prefix    = filterPrefix.len() ? filterPrefix & "." : "";
		var filterSql = "#prefix##propertyName# ${operator} :#paramName#";
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

		return [ { filterParams=params, having=filterSql } ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
	) {
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.numericFormulaPropertyCompares.label", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:numericFormulaPropertyCompares.label", data=[ propNameTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
	){
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.numericFormulaPropertyCompares.text", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:numericFormulaPropertyCompares.text", data=[ propNameTranslated ] );
	}

}