/**
 * Dynamic expression handler for checking whether or not a preside object
 * enum property's value matches the supplied enum option
 *
 * @feature rulesEngine
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          boolean _is       = true
		,          string  enumValue = ""
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
		,          boolean _is          = true
		,          string  enumValue    = ""
	){
		var paramName = "enumPropertyMatches" & CreateUUId().lCase().replace( "-", "", "all" );
		var filterSql = "#arguments.objectName#.#propertyName# ${operator} (:#paramName#)";
		var params    = { "#paramName#" = { value=arguments.enumValue, type="cf_sql_varchar", list=true } };

		if ( _is ) {
			filterSql = filterSql.replace( "${operator}", "in" );
		} else {
			filterSql = filterSql.replace( "${operator}", "not in" );
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
			return translateResource( uri="rules.dynamicExpressions:related.enumPropertyMatches.label", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:enumPropertyMatches.label", data=[ propNameTranslated ] );
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
			return translateResource( uri="rules.dynamicExpressions:related.enumPropertyMatches.text", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:enumPropertyMatches.text", data=[ propNameTranslated ] );
	}

}