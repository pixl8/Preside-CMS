/**
 * Dynamic expression handler for checking whether or not a preside object
 * formula property's value matches the supplied text
 *
 * @feature rulesEngine
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService"     inject="presideObjectService";
	property name="rulesEngineFilterService" inject="rulesEngineFilterService";

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
		switch ( arguments._stringOperator ) {
			case "oneof":
			case "noneof":
				arguments.value = ListItemTrim( arguments.value );
		}

		var paramName = "textFormulaPropertyMatches" & Replace( LCase( CreateUUID() ), "-", "", "all" );
		var filterSql = "#arguments.propertyName# ${operator} :#paramName#";
		var params    = { "#paramName#" = { value=arguments.value, type="cf_sql_varchar" } };

		switch ( _stringOperator ) {
			case "eq":
				filterSql = Replace( filterSql, "${operator}", "=" );
			break;
			case "neq":
				filterSql = Replace( filterSql, "${operator}", "!=" );
			break;
			case "contains":
				params[ paramName ].value = "%#arguments.value#%";
				filterSql = Replace( filterSql, "${operator}", "like" );
			break;
			case "startsWith":
				params[ paramName ].value = "#arguments.value#%";
				filterSql = Replace( filterSql, "${operator}", "like" );
			break;
			case "endsWith":
				params[ paramName ].value = "%#arguments.value#";
				filterSql = Replace( filterSql, "${operator}", "like" );
			break;
			case "notcontains":
				params[ paramName ].value = "%#arguments.value#%";
				filterSql = Replace( filterSql, "${operator}", "not like" );
			break;
			case "notstartsWith":
				params[ paramName ].value = "#arguments.value#%";
				filterSql = Replace( filterSql, "${operator}", "not like" );
			break;
			case "notendsWith":
				params[ paramName ].value = "%#arguments.value#";
				filterSql = Replace( filterSql, "${operator}", "not like" );
			break;
			case "oneof":
				params[ paramName ].value = ListToArray( arguments.value );
				filterSql = Replace( filterSql, "${operator}", "in", "all" );
				filterSql = Replace( filterSql, ":#paramName#", "(:#paramName#)", "all" );
			break;
			case "noneof":
				params[ paramName ].value = ListToArray( arguments.value );
				filterSql = Replace( filterSql, "${operator}", "not in", "all" );
				filterSql = Replace( filterSql, ":#paramName#", "(:#paramName#)", "all" );
			break;
		}

		return [ rulesEngineFilterService.prepareAutoFormulaFilter(
			  objectName   = arguments.objectName
			, propertyName = arguments.propertyName
			, filter       = filterSql
			, filterParams = params
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