/**
 * Dynamic expression handler for checking whether or not a preside object
 * many-to-one property's value matches the selected related records
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          boolean _is   = true
		,          string  value = ""
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
		,          boolean _is   = true
		,          string  value = ""
	){
		var paramName = "manyToOneMatch" & CreateUUId().lCase().replace( "-", "", "all" );
		var operator  = _is ? "in" : "not in";
		var filterSql = "#objectName#.#propertyName# #operator# (:#paramName#)";
		var params    = { "#paramName#" = { value=arguments.value, type="cf_sql_varchar", list=true } };

		return [ { filter=filterSql, filterParams=params } ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
	) {
		var objectBaseUri       = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToBaseUri    = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var propNameTranslated  = translateResource( objectBaseUri & "field.#propertyName#.title", propertyName );
		var relatedToTranslated = translateResource( relatedToBaseUri & "title", relatedTo );

		return translateResource( uri="rules.dynamicExpressions:manyToOneMatch.label", data=[ propNameTranslated, relatedToTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		, required string relatedTo
	){
		var objectBaseUri       = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToBaseUri    = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var propNameTranslated  = translateResource( objectBaseUri & "field.#propertyName#.title", propertyName );
		var relatedToTranslated = translateResource( relatedToBaseUri & "title", relatedTo );

		return translateResource( uri="rules.dynamicExpressions:manyToOneMatch.text", data=[ propNameTranslated, relatedToTranslated ] );
	}

}