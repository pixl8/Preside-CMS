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
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          boolean _possesses = true
		,          string  value      = ""
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
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
	) {
		var objectBaseUri        = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToBaseUri     = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var objectNameTranslated = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated  = translateResource( relatedToBaseUri & "title", relatedTo );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = translateObjectProperty( parentObjectName, parentPropertyName, translateObjectName( objectName ) );
			return translateResource( uri="rules.dynamicExpressions:related.manyToManyMatch.label", data=[ objectNameTranslated, relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:manyToManyMatch.label", data=[ objectNameTranslated, relatedToTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		, required string relatedTo
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	){
		var objectBaseUri        = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToBaseUri     = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var objectNameTranslated = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated  = translateResource( relatedToBaseUri & "title", relatedTo );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = translateObjectProperty( parentObjectName, parentPropertyName, translateObjectName( objectName ) );
			return translateResource( uri="rules.dynamicExpressions:related.manyToManyMatch.text", data=[ objectNameTranslated, relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:manyToManyMatch.text", data=[ objectNameTranslated, relatedToTranslated ] );
	}

}