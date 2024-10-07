/**
 * Dynamic expression handler for checking whether or not a preside object
 * string property's value matches the supplied text
 *
 * @feature rulesEngine
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";
	property name="enumService"          inject="enumService";

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

		var paramName     = "textPropertyMatches" & Replace( LCase( CreateUUId() ), "-", "", "all" );
		var filterSql     = "#arguments.objectName#.#propertyName# ${operator} :#paramName#";
		var params        = { "#paramName#" = { value=arguments.value, type="cf_sql_varchar" } };
		var fieldEnumName = presideObjectService.getObjectPropertyAttribute(
			  objectName    = arguments.objectName
			, propertyName  = arguments.propertyName
			, attributeName = "enum"
		);

		if ( !isEmpty( fieldEnumName ) ) {
			var enumFilterSql = "";
			var enumDelim     = ArrayFind( [ "neq", "notcontains", "notstartswith", "notendsWith", "noneof" ], arguments._stringOperator ) ? "and" : "or";
			var items         = enumService.listItems( fieldEnumName );

			for ( var item in items ) {
				var isMatched = false;
				switch ( arguments._stringOperator ) {
					case "eq":
					case "neq":
						isMatched = arguments.value == item.label;
					break;
					case "contains":
					case "notcontains":
						isMatched = FindNoCase( arguments.value, item.label );
					break;
					case "startsWith":
					case "notstartsWith":
						isMatched = Left( item.label, Len( arguments.value ) ) == arguments.value;
					break;
					case "endsWith":
					case "notendsWith":
						isMatched = Right( item.label, Len( arguments.value ) ) == arguments.value;
					break;
					case "oneof":
					case "noneof":
						isMatched = ListFindNoCase(  arguments.value, item.label );
					break;
				}
				if ( isMatched || item.id == arguments.value ) {
					var enumParamName       = "enum#paramName##item.id#";
					enumFilterSql          &= ( Len( enumFilterSql ) ? " #enumDelim# " : "" ) & "#arguments.objectName#.#propertyName#" & " ${operator} :#enumParamName#";
					params[ enumParamName ] = { type="varchar", value=item.id };

					switch ( arguments._stringOperator ) {
						case "oneof":
						case "noneof":
							enumFilterSql = Replace( enumFilterSql, ":#enumParamName#", "(:#enumParamName#)", "all" );
						break;
					}
				}
			}
			if ( Len( enumFilterSql ) ) {
				filterSql = "( ( #filterSql# ) #enumDelim# ( #enumFilterSql# ) )";
			}
		}

		switch ( _stringOperator ) {
			case "eq":
				filterSql = Replace( filterSql, "${operator}", "=", "all" );
			break;
			case "neq":
				filterSql = Replace( filterSql, "${operator}", "!=", "all" );
			break;
			case "contains":
				params[ paramName ].value = "%#arguments.value#%";
				filterSql = Replace( filterSql, "${operator}", "like", "all" );
			break;
			case "startsWith":
				params[ paramName ].value = "#arguments.value#%";
				filterSql = Replace( filterSql, "${operator}", "like", "all" );
			break;
			case "endsWith":
				params[ paramName ].value = "%#arguments.value#";
				filterSql = Replace( filterSql, "${operator}", "like", "all" );
			break;
			case "notcontains":
				params[ paramName ].value = "%#arguments.value#%";
				filterSql = Replace( filterSql, "${operator}", "not like", "all" );
			break;
			case "notstartsWith":
				params[ paramName ].value = "#arguments.value#%";
				filterSql = Replace( filterSql, "${operator}", "not like", "all" );
			break;
			case "notendsWith":
				params[ paramName ].value = "%#arguments.value#";
				filterSql = Replace( filterSql, "${operator}", "not like", "all" );
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

		return [ { filter=filterSql, filterParams=params } ];
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
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );

			return translateResource( uri="rules.dynamicExpressions:related.textPropertyMatches.text", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:textPropertyMatches.text", data=[ propNameTranslated ] );
	}

}