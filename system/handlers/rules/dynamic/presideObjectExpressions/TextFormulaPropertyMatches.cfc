/**
 * Dynamic expression handler for checking whether or not a preside object
 * formula property's value matches the supplied text
 *
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {
	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          string  _stringOperator = "contains"
		,          string  value           = ""
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
		,          string  _stringOperator = "contains"
		,          string  value           = ""
	){
		var paramName           = "textFormulaPropertyMatches" & CreateUUId().lCase().replace( "-", "", "all" );
		var formulaPropertyName = "#arguments.objectName#.#propertyName#";
		var filterSql           = "#formulaPropertyName# ${operator} :#paramName#";
		var params              = { "#paramName#" = { value=arguments.value, type="cf_sql_varchar" } };

		switch ( _stringOperator ) {
			case "eq":
				filterSql = filterSql.replace( "${operator}", "=" );
			break;
			case "neq":
				filterSql = filterSql.replace( "${operator}", "!=" );
			break;
			case "contains":
				params[ paramName ].value = "%#arguments.value#%";
				filterSql = filterSql.replace( "${operator}", "like" );
			break;
			case "startsWith":
				params[ paramName ].value = "#arguments.value#%";
				filterSql = filterSql.replace( "${operator}", "like" );
			break;
			case "endsWith":
				params[ paramName ].value = "%#arguments.value#";
				filterSql = filterSql.replace( "${operator}", "like" );
			break;
			case "notcontains":
				params[ paramName ].value = "%#arguments.value#%";
				filterSql = filterSql.replace( "${operator}", "not like" );
			break;
			case "notstartsWith":
				params[ paramName ].value = "#arguments.value#%";
				filterSql = filterSql.replace( "${operator}", "not like" );
			break;
			case "notendsWith":
				params[ paramName ].value = "%#arguments.value#";
				filterSql = filterSql.replace( "${operator}", "not like" );
			break;
		}

		return [ { having=filterSql, filterParams=params, propertyName=formulaPropertyName } ];
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
			return translateResource( uri="rules.dynamicExpressions:related.textFormulaPropertyMatches.label", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:textFormulaPropertyMatches.label", data=[ propNameTranslated ] );
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

			return translateResource( uri="rules.dynamicExpressions:related.textFormulaPropertyMatches.text", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:textFormulaPropertyMatches.text", data=[ propNameTranslated ] );
	}
}