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
		, required string  relatedTo
		, required string  relationshipKey
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
		, required string  relatedTo
		, required string  relationshipKey
		,          boolean _is   = true
		,          string  value = ""
	){
		var paramName = "oneToManyMatch" & CreateUUId().lCase().replace( "-", "", "all" );
		var filterParams = { "#paramName#" = { value=arguments.value, type="cf_sql_varchar", list=true } };

		if ( _is ) {
			return [ {
				  filter       = "#propertyName#.id in (:#paramName#)"
				, filterParams = { "#paramName#" = { value=arguments.value, type="cf_sql_varchar", list=true } }
			} ];
		}

		var params        = {};
		var subQueryAlias = paramName;
		var subQuery      = presideObjectService.selectData(
			  objectName          = arguments.relatedTo
			, selectFields        = [ "#arguments.relationshipKey#.id" ]
			, forceJoins          = "inner"
			, getSqlAndParamsOnly = true
			, filter              = { "#arguments.relatedTo#.id" = arguments.value }
		);
		for( var param in subQuery.params ) {
			params[ param.name ] = param;
			params[ param.name ].delete( "name" );
		}

		return [ {
			  filter = "#subQueryAlias#.id is null"
			, filterParams = params
			, extraJoins = [{
				  type           = "left"
				, subQuery       = subQuery.sql
				, subQueryAlias  = subQueryAlias
				, subQueryColumn = "id"
				, joinToTable    = arguments.objectName
				, joinToColumn   = "id"
			} ]
		}];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
		, required string  relationshipKey
	) {
		var relatedToBaseUri     = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var relatedPropertyTranslated = translateResource( relatedToBaseUri & "field.#relationshipKey#.title", relationshipKey );
		var relatedToTranslated  = translateResource( relatedToBaseUri & "title", relatedTo );

		return translateResource( uri="rules.dynamicExpressions:oneToManyMatch.label", data=[ relatedToTranslated, relatedPropertyTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		, required string relatedTo
		, required string relationshipKey
	){
		var relatedToBaseUri          = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var relatedPropertyTranslated = translateResource( relatedToBaseUri & "field.#relationshipKey#.title", relationshipKey );
		var relatedToTranslated       = translateResource( relatedToBaseUri & "title", relatedTo );

		return translateResource( uri="rules.dynamicExpressions:oneToManyMatch.text", data=[ relatedToTranslated, relatedPropertyTranslated ] );
	}

}