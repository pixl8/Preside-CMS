/**
 * Dynamic expression handler for checking whether or not a preside object
 * many-to-one property's value matches the selected related records
 *
 * @feature rulesEngine
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";
	property name="filterService"        inject="rulesEngineFilterService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          string  value = ""
	) {
		return presideObjectService.dataExists(
			  objectName   = arguments.objectName
			, id           = payload[ arguments.objectName ].id ?: ""
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
		,          string  value        = ""
	){
		var relatedToSameObject = ( arguments.objectName==relatedTo );
		var expressionArray     = filterService.getExpressionArrayForSavedFilter( arguments.value );
		if ( !expressionArray.len() ) {
			return [];
		}
		var idField = presideObjectService.getIdField( arguments.relatedTo );
		var extraFilter = filterService.prepareFilter(
			  objectName      = arguments.relatedTo
			, expressionArray = expressionArray
		);

		var subQueryFilter = relatedToSameObject ? "" : obfuscateSqlForPreside( "#arguments.relatedTo#.#idField# = #arguments.objectName#.#arguments.propertyName#" );
		var subQuery = presideObjectService.selectData(
			  objectName          = arguments.relatedTo
			, selectFields        = [ "id" ]
			, extraFilters        = [ extraFilter ]
			, filter              = subQueryFilter
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		if ( relatedToSameObject ) {
			var dbAdapter               = getPresideObject( arguments.objectName ).getDbAdapter();
			var subQueryAlias           = dbAdapter.escapeEntity( "subquery_#arguments.objectName#" );
			var idFieldEscaped          = dbAdapter.escapeEntity( idField );
			var relatedFieldEscapedFull = dbAdapter.escapeEntity( "#arguments.objectName#.#arguments.propertyName#" );

			var subQuerySql = obfuscateSqlForPreside( "
				select #idFieldEscaped#
				from (#subQuery.sql#) as #subQueryAlias#
				where #relatedFieldEscapedFull# = #subQueryAlias#.#idField#
			" );
		} else {
			var subQuerySql = subQuery.sql;
		}

		return [ {
			  filter       = obfuscateSqlForPreside( "exists (#subQuerySql#)" )
			, filterParams = subQuery.params
		}];
	}

	private string function getLabel(
		  required string objectName
		, required string propertyName
		, required string relatedTo
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
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
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
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