/**
 * Dynamic expression handler for checking whether or not a preside object
 * many-to-many relationships match the selected related records
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          boolean _possesses = true
		,          string  value      = ""
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
		,          boolean _possesses = true
		,          string  value      = ""
	){
		var paramName = "manyToManyMatch" & CreateUUId().lCase().replace( "-", "", "all" );
		var operator  = _possesses ? "in" : "not in";
		var prefix    = filterPrefix.len() ? filterPrefix : propertyName;
		var filterSql = "#prefix#.id #operator# (:#paramName#)";
		var params    = { "#paramName#" = { value=arguments.value, type="cf_sql_varchar", list=true } };

		return [ { filter=filterSql, filterParams=params } ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
	) {
		var objectBaseUri        = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToBaseUri     = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var objectNameTranslated = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated  = translateResource( relatedToBaseUri & "title", relatedTo );

		return translateResource( uri="rules.dynamicExpressions:manyToManyMatch.label", data=[ objectNameTranslated, relatedToTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		, required string relatedTo
	){
		var objectBaseUri        = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToBaseUri     = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var objectNameTranslated = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated  = translateResource( relatedToBaseUri & "title", relatedTo );

		return translateResource( uri="rules.dynamicExpressions:manyToManyMatch.text", data=[ objectNameTranslated, relatedToTranslated ] );
	}

}