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
		var expressionArray = filterService.getExpressionArrayForSavedFilter( arguments.value );
		if ( !expressionArray.len() ) {
			return [];
		}
		var idField = presideObjectService.getIdField( arguments.relatedTo );
		var filter = filterService.prepareFilter(
			  objectName      = arguments.relatedTo
			, expressionArray = expressionArray
		);
		var subQueryAlias = "manyToOneFilter" & CreateUUId().lCase().replace( "-", "", "all" );
		var subQuery = presideObjectService.selectData(
			  objectName          = arguments.relatedTo
			, selectFields        = [ "#idField# as id" ]
			, extraFilters        = [ filter ]
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);
		var adapter = presideObjectService.getDbAdapterForObject( arguments.objectName );

		return [ {
			  filter = "#adapter.escapeEntity( '#subQueryAlias#.id' )# is not null"
			, filterParams = subquery.params
			, extraJoins = [{
				  type           = "left"
				, subQuery       = subQuery.sql
				, subQueryAlias  = subQueryAlias
				, subQueryColumn = "id"
				, joinToTable    = arguments.objectName
				, joinToColumn   = arguments.propertyName
			} ]
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