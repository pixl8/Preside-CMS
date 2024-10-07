/**
 * Dynamic expression handler for checking whether or not a preside object
 * one-to-many relationships has any relationships
 *
 * @feature rulesEngine
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";
	property name="filterService"        inject="rulesEngineFilterService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          boolean _is                = true
		,          string  savedFilter        = ""
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
		, required string  relationshipKey
		,          boolean _is                = true
		,          string  savedFilter        = ""
	){
		var params               = {};
		var subQueryExtraFilters = [];

		if ( Len( Trim( arguments.savedFilter ) ) ) {
			ArrayAppend( subQueryExtraFilters, filterService.prepareFilter( arguments.relatedTo, arguments.savedFilter ) );
		}
		for( var extraFilter in subQueryExtraFilters ) {
			StructAppend( params, extraFilter.filterParams ?: {} );
		}

		var dbAdapter = getPresideObject( arguments.objectName ).getDbAdapter();
		var subQuery  = presideObjectService.selectData(
			  objectName          = arguments.relatedTo
			, selectFields        = [ arguments.relationshipKey ]
			, extraFilters        = subQueryExtraFilters
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		var subQueryAlias      = dbAdapter.escapeEntity( "subquery_#arguments.relatedTo#" );
		var idField            = presideObjectService.getIdField( arguments.objectName );
		var idFieldEscapedFull = dbAdapter.escapeEntity( "#arguments.objectName#.#idField#" );
		var exists             = arguments._is ? "exists" : "not exists";
		var subQuerySql        = obfuscateSqlForPreside( "
			select 1
			from (#subQuery.sql#) as #subQueryAlias#
			where #idFieldEscapedFull# = #subQueryAlias#.#arguments.relationshipKey#
		" );

		StructAppend( params, subquery.params );

		return [ {
			  filter       = obfuscateSqlForPreside( "#exists# (#subQuerySql#)" )
			, filterParams = params
		}];
	}

	private string function getLabel(
		  required string objectName
		, required string propertyName
		, required string relatedTo
		, required string relationshipKey
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	) {
		var objectBaseUri       = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToTranslated = translateObjectProperty( objectName, propertyName );
		var possesses           = translateResource(
			  uri          = objectBaseUri & "field.#propertyName#.possesses.truthy"
			, defaultValue = translateResource( "rules.dynamicExpressions:boolean.possesses.with.negative" )
		);

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
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
		var relatedToTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.oneToManyHas.text", data=[ relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:oneToManyHas.text", data=[ relatedToTranslated ] );
	}

}