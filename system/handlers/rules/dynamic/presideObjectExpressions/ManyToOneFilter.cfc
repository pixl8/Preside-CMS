/**
 * Dynamic expression handler for checking whether or not a preside object
 * many-to-one property's value matches the selected related records
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
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          string  filterPrefix = ""
		,          string  value        = ""
	){
		var prefix          = Len( arguments.filterPrefix ) ? arguments.filterPrefix : ( Len( arguments.parentPropertyName ) ? arguments.parentPropertyName : arguments.objectName );
		var expressionArray = filterService.getExpressionArrayForSavedFilter( arguments.value );
		if ( !expressionArray.len() ) {
			return [];
		}
		var idField = presideObjectService.getIdField( arguments.relatedTo );
		var extraFilter = filterService.prepareFilter(
			  objectName      = arguments.relatedTo
			, expressionArray = expressionArray
		);
		var subQueryFilter = obfuscateSqlForPreside( "#arguments.relatedTo#.#idField# = #prefix#.#arguments.propertyName#" );
		var subQuery = presideObjectService.selectData(
			  objectName          = arguments.relatedTo
			, selectFields        = [ "1" ]
			, extraFilters        = [ extraFilter ]
			, filter              = subQueryFilter
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		if ( !Len( arguments.parentObjectName ) || arguments.parentObjectName == arguments.objectName ) {
			return [ {
				  filter       = obfuscateSqlForPreside( "exists (#subQuery.sql#)" )
				, filterParams = subQuery.params
			}];
		}

		var outerJoin = "#arguments.parentObjectName#.#arguments.parentPropertyName#";
		var outerIdField = presideObjectService.getIdField( arguments.objectName );
		var outerSubQuery = presideObjectService.selectData(
			  objectName          = arguments.objectName
			, selectFields        = [ "1" ]
			, filter              = obfuscateSqlForPreside( "#outerJoin#=#arguments.objectName#.#outerIdField#" )
			, extraFilters        = [ { filter=obfuscateSqlForPreside( "exists (#subQuery.sql#)" ) }]
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);
		var params = subQuery.params;
		StructAppend( params, outerSubQuery.params );

		return [ {
			  filter = obfuscateSqlForPreside( "exists (#outerSubQuery.sql#)" )
			, filterParams = params
		}];
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
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.manyToOneFilter.label", data=[ propNameTranslated, relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:manyToOneFilter.label", data=[ propNameTranslated, relatedToTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		, required string relatedTo
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
	){
		var relatedToBaseUri    = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var relatedToTranslated = translateResource( relatedToBaseUri & "title", relatedTo );
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.manyToOneFilter.text", data=[ propNameTranslated, relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:manyToOneFilter.text", data=[ propNameTranslated, relatedToTranslated ] );
	}

}