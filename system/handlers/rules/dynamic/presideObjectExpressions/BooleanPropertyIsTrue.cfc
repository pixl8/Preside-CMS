/**
 * Dynamic expression handler for checking whether or not a preside object
 * boolean property's value is true / fase
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          boolean _is = true
	) {
		var recordId = payload[ objectName ].id ?: "";

		return presideObjectService.dataExists(
			  objectName   = objectName
			, id           = recordId
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string  objectName
		, required string  propertyName
		,          string  filterPrefix = ""
		,          boolean _is = true
	){
		var paramName = "booleanPropertyIsTrue" & CreateUUId().lCase().replace( "-", "", "all" );
		var prefix    = filterPrefix.len() ? filterPrefix : objectName;

		return [ {
			  filter       = "#prefix#.#propertyName# = :#paramName#"
			, filterParams = { "#paramName#" = { value=arguments._is, type="cf_sql_boolean" } }
		} ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
	) {
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		return translateResource( uri="rules.dynamicExpressions:booleanPropertyIsTrue.label", data=[ propNameTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
	){
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		return translateResource( uri="rules.dynamicExpressions:booleanPropertyIsTrue.text", data=[ propNameTranslated ] );
	}

}