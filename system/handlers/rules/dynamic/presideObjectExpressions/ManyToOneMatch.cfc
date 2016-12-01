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
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          boolean _is   = true
		,          string  value = ""
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
		,          boolean _is   = true
		,          string  value = ""
	){
		var paramName = "manyToOneMatch" & CreateUUId().lCase().replace( "-", "", "all" );
		var operator  = _is ? "in" : "not in";
		var prefix    = filterPrefix.len() ? filterPrefix : ( parentPropertyName.len() ? parentPropertyName : objectName );
		var filterSql = "#prefix#.#propertyName# #operator# (:#paramName#)";
		var params    = { "#paramName#" = { value=arguments.value, type="cf_sql_varchar", list=true } };

		return [ { filter=filterSql, filterParams=params } ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
	) {
		var relatedToBaseUri    = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var relatedToTranslated = translateResource( relatedToBaseUri & "title", relatedTo );
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = translateObjectProperty( parentObjectName, parentPropertyName, translateObjectName( objectName ) );
			return translateResource( uri="rules.dynamicExpressions:related.manyToOneMatch.label", data=[ propNameTranslated, relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:manyToOneMatch.label", data=[ propNameTranslated, relatedToTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		, required string relatedTo
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	){
		var relatedToBaseUri    = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var relatedToTranslated = translateResource( relatedToBaseUri & "title", relatedTo );
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = translateObjectProperty( parentObjectName, parentPropertyName, translateObjectName( objectName ) );
			return translateResource( uri="rules.dynamicExpressions:related.manyToOneMatch.text", data=[ propNameTranslated, relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:manyToOneMatch.text", data=[ propNameTranslated, relatedToTranslated ] );
	}

}