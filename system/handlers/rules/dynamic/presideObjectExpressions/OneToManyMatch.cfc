/**
 * Dynamic expression handler for checking whether or not a preside object
 * many-to-many relationships match the selected related records
 *
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
		, required string  relationshipKey
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
		, required string  relatedTo
		, required string  relationshipKey
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          string  filterPrefix = ""
		,          boolean _is   = true
		,          string  value = ""
	){
		var defaultPrefix  = parentPropertyName.len() ? "#parentPropertyName#$#propertyName#" : propertyName;
		var prefix         = filterPrefix.len() ? ( filterPrefix & "$#propertyName#" ) : defaultPrefix;
		var paramName      = "oneToManyMatch" & CreateUUId().lCase().replace( "-", "", "all" );
		var relatedIdField = presideObjectService.getIdField( arguments.relatedTo );

		if ( _is ) {
			return [ {
				  filter       = "#prefix#.#relatedIdField# in (:#paramName#)"
				, filterParams = { "#paramName#" = { value=arguments.value, type="cf_sql_varchar", list=true } }
			} ];
		}

		var params        = {};
		var subQueryAlias = paramName;
		var subQuery      = presideObjectService.selectData(
			  objectName          = arguments.relatedTo
			, selectFields        = [ "#arguments.relatedTo#.#arguments.relationshipKey# as id" ]
			, forceJoins          = "inner"
			, getSqlAndParamsOnly = true
			, filter              = { "#arguments.relatedTo#.#relatedIdField#" = listToArray( arguments.value ) }
		);
		for( var param in subQuery.params ) {
			params[ param.name ] = param;
			params[ param.name ].delete( "name" );
		}

		prefix = filterPrefix.len() ? filterPrefix : ( parentPropertyName.len() ? parentPropertyName : objectName );

		return [ {
			  filter = "#subQueryAlias#.id is null"
			, filterParams = params
			, extraJoins = [{
				  type           = "left"
				, subQuery       = subQuery.sql
				, subQueryAlias  = subQueryAlias
				, subQueryColumn = "id"
				, joinToTable    = prefix
				, joinToColumn   = presideObjectService.getIdField( objectName )
			} ]
		}];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
		, required string  relationshipKey
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
	) {
		var objectBaseUri       = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToBaseUri    = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var relatedToTranslated = translateResource( relatedToBaseUri & "title", relatedTo );
		var possesses           = translateResource(
			  uri          = objectBaseUri & "field.#propertyName#.possesses.truthy"
			, defaultValue = translateResource( "rules.dynamicExpressions:boolean.possesses" )
		);

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.oneToManyMatch.label", data=[ relatedToTranslated, possesses, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:oneToManyMatch.label", data=[ relatedToTranslated, possesses ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		, required string relatedTo
		, required string relationshipKey
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
	){
		var relatedToBaseUri          = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var relatedToTranslated       = translateResource( relatedToBaseUri & "title", relatedTo );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.oneToManyMatch.text", data=[ relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:oneToManyMatch.text", data=[ relatedToTranslated ] );
	}

}