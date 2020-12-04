/**
 * Dynamic expression handler for checking the number
 * of records in a many-to-many relationship
 *
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";
	property name="filterService"        inject="rulesEngineFilterService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          boolean _possesses         = true
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
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
		,          boolean _possesses         = true
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

		var objIdField = presideObjectService.getIdField( arguments.objectName );
		var subQuery = presideObjectService.selectData(
			  objectName          = arguments.objectName
			, selectFields        = [ "Count( #propertyName#.#objIdField# ) as manytomany_count", "#objectName#.#objIdField# as id" ]
			, groupBy             = "#objectName#.#objIdField#"
			, extraFilters        = subQueryExtraFilters
			, getSqlAndParamsOnly = true
		);

		var subQueryAlias = "manyToManyHas" & CreateUUId().lCase().replace( "-", "", "all" );
		var paramName     = subQueryAlias;
		var filterSql     = "";
		var params        = {};

		for( var param in subQuery.params ) {
			params[ param.name ] = param;
			params[ param.name ].delete( "name" );
		}

		if ( _possesses ) {
			filterSql = "#subQueryAlias#.manytomany_count > 0";
		} else {
			filterSql = "( #subQueryAlias#.manytomany_count is null or #subQueryAlias#.manytomany_count = 0 )";
		}

		var prefix = filterPrefix.len() ? filterPrefix : ( parentPropertyName.len() ? parentPropertyName : objectName );

		return [ { filter=filterSql, filterParams=params, extraJoins=[ {
			  type           = "left"
			, subQuery       = subQuery.sql
			, subQueryAlias  = subQueryAlias
			, subQueryColumn = "id"
			, joinToTable    = prefix
			, joinToColumn   = objIdField
		} ] } ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
	) {
		var objectBaseUri        = presideObjectService.getResourceBundleUriRoot( objectName );
		var objectNameTranslated = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated  = translateObjectProperty( objectName, propertyName );
		var possesses            = translateResource(
			  uri          = objectBaseUri & "field.#propertyName#.possesses.truthy"
			, defaultValue = translateResource( "rules.dynamicExpressions:boolean.possesses.with.negative" )
		);

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.manyToManyHas.label", data=[ objectNameTranslated, relatedToTranslated, parentPropNameTranslated, possesses ] );
		}

		return translateResource( uri="rules.dynamicExpressions:manyToManyHas.label", data=[ objectNameTranslated, relatedToTranslated, possesses ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		, required string relatedTo
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	){
		var objectBaseUri        = presideObjectService.getResourceBundleUriRoot( objectName );
		var objectNameTranslated = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated  = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.manyToManyHas.text", data=[ objectNameTranslated, relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:manyToManyHas.text", data=[ objectNameTranslated, relatedToTranslated ] );
	}

}