/**
 * Dynamic expression handler for checking whether or not a preside object
 * one-to-many relationships has any relationships
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";
	property name="filterService"        inject="rulesEngineFilterService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          boolean _is                = true
		,          string  savedFilter        = ""
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
		,          string  filterPrefix       = ""
		,          boolean _is                = true
		,          string  savedFilter        = ""
	){
		var subQueryExtraFilters = [];
		if ( Len( Trim( arguments.savedFilter ) ) ) {
			var expressionArray = filterService.getExpressionArrayForSavedFilter( arguments.savedFilter );
			if ( expressionArray.len() ) {
				subQueryExtraFilters.append(
					filterService.prepareFilter(
						  objectName      = arguments.relatedTo
						, expressionArray = expressionArray
						, filterPrefix    = arguments.propertyName
					)
				);
			}
		}

		var idField        = presideObjectService.getIdField( objectName );
		var relatedIdField = presideObjectService.getIdField( relatedTo );
		var subQuery       = presideObjectService.selectData(
			  objectName          = arguments.objectName
			, selectFields        = [ "Count( #propertyName#.#relatedIdField# ) as onetomany_count", "#objectName#.#idField# as id" ]
			, groupBy             = "#objectName#.#idField#"
			, extraFilters        = subQueryExtraFilters
			, getSqlAndParamsOnly = true
		);
		var subQueryParams = {};
		var subQueryAlias = "manyToManyCount" & CreateUUId().lCase().replace( "-", "", "all" );
		var filterSql     = "#subQueryAlias#.onetomany_count ${operator} 0";

		for( var param in subQuery.params ) {
			subQueryParams[ param.name ] = param;
		}

		if ( _is ) {
			filterSql = filterSql.replace( "${operator}", ">" );
		} else {
			filterSql = filterSql.replace( "${operator}", "=" );
		}

		var prefix = filterPrefix.len() ? filterPrefix : ( parentPropertyName.len() ? parentPropertyName : objectName );

		return [ { filter=filterSql, filterParams=subQueryParams, extraJoins=[ {
			  type           = "left"
			, subQuery       = subQuery.sql
			, subQueryAlias  = subQueryAlias
			, subQueryColumn = "id"
			, joinToTable    = prefix
			, joinToColumn   = idField
		} ] } ];
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
			var parentPropNameTranslated = translateObjectProperty( parentObjectName, parentPropertyName, translateObjectName( objectName ) );
			return translateResource( uri="rules.dynamicExpressions:related.oneToManyHas.label", data=[ relatedToTranslated, possesses, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:oneToManyHas.label", data=[ relatedToTranslated, possesses ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		, required string relatedTo
		, required string relationshipKey
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	){
		var relatedToBaseUri    = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var relatedToTranslated = translateResource( relatedToBaseUri & "title", relatedTo );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = translateObjectProperty( parentObjectName, parentPropertyName, translateObjectName( objectName ) );
			return translateResource( uri="rules.dynamicExpressions:related.oneToManyHas.text", data=[ relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:oneToManyHas.text", data=[ relatedToTranslated ] );
	}

}