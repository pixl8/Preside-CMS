/**
 * Dynamic expression handler for checking whether or not a preside object
 * enum formula property's value matches the supplied enum option
 *
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
		var paramName           = "enumFormulaPropertyMatches" & CreateUUId().lCase().replace( "-", "", "all" );
		var formulaPropertyName = "#arguments.objectName#.#propertyName#";
		var filterSql           = "#formulaPropertyName# ${operator} (:#paramName#)";
		var params              = { "#paramName#" = { value=arguments.enumValue, type="cf_sql_varchar", list=true } };

		if ( _is ) {
			filterSql = filterSql.replace( "${operator}", "in" );
		} else {
			filterSql = filterSql.replace( "${operator}", "not in" );
		}

		return [ { filterParams=params, having=filterSql, propertyName=formulaPropertyName } ];
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
			return translateResource( uri="rules.dynamicExpressions:related.enumFormulaPropertyMatches.label", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:enumFormulaPropertyMatches.label", data=[ propNameTranslated ] );
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
			return translateResource( uri="rules.dynamicExpressions:related.enumFormulaPropertyMatches.text", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:enumFormulaPropertyMatches.text", data=[ propNameTranslated ] );
	}

}