/**
 * Dynamic expression handler for checking whether or not a preside object
 * string property's value matches the supplied text
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          string  _stringOperator = "contains"
		,          string  value           = ""
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
		,          string  _stringOperator = "contains"
		,          string  value           = ""
	){
		var prefix    = filterPrefix.len() ? filterPrefix : ( parentPropertyName.len() ? parentPropertyName : objectName );
		var paramName = "textPropertyMatches" & CreateUUId().lCase().replace( "-", "", "all" );
		var filterSql = "#prefix#.#propertyName# ${operator} :#paramName#";
		var params    = { "#paramName#" = { value=arguments.value, type="cf_sql_varchar" } };

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

		return [ { filter=filterSql, filterParams=params } ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
	) {
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = translateObjectProperty( parentObjectName, parentPropertyName, translateObjectName( objectName ) );
			return translateResource( uri="rules.dynamicExpressions:related.textPropertyMatches.label", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:textPropertyMatches.label", data=[ propNameTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	){
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = translateObjectProperty( parentObjectName, parentPropertyName, translateObjectName( objectName ) );

			return translateResource( uri="rules.dynamicExpressions:related.textPropertyMatches.text", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:textPropertyMatches.text", data=[ propNameTranslated ] );
	}

}