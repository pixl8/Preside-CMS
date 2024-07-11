/**
 * Dynamic expression handler for checking the number
 * of records in a one-to-many relationship
 *
 * @feature rulesEngine
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";
	property name="filterService"        inject="rulesEngineFilterService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          string  _numericOperator = "eq"
		,          string  savedFilter      = ""
		,          numeric value            = 0
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
		,          string  savedFilter        = ""
		,          string  _numericOperator   = "eq"
		,          numeric value              = 0
	){
		var params               = {};
		var subQueryExtraFilters = [];

		if ( Len( Trim( arguments.savedFilter ) ) ) {
			ArrayAppend( subQueryExtraFilters, filterService.prepareFilter( arguments.relatedTo, arguments.savedFilter ) );
		}
		for( var extraFilter in subQueryExtraFilters ) {
			StructAppend( params, extraFilter.filterParams ?: {} );
		}

		var subquery  = presideObjectService.selectData(
			  objectName          = arguments.relatedTo
			, selectFields        = [ arguments.relationshipKey ]
			, extraFilters        = subQueryExtraFilters
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		var dbAdapter          = getPresideObject( arguments.objectName ).getDbAdapter();
		var subQueryAlias      = dbAdapter.escapeEntity( "subquery_#arguments.relatedTo#" );
		var idField            = presideObjectService.getIdField( arguments.objectName );
		var idFieldEscapedFull = dbAdapter.escapeEntity( "#arguments.objectName#.#idField#" );
		var countOperator      = rulesEngineNumericOperatorToSqlOperator( arguments._numericOperator );
		var countParam         = "oneToManyCount" & CreateUUId().lCase().replace( "-", "", "all" );
		var countField         = "#subQueryAlias#.#arguments.relationshipKey#";
		var subQuerySql        = obfuscateSqlForPreside( "
			select 1
			from (#subQuery.sql#) as #subQueryAlias#
			where #idFieldEscapedFull# = #countField#
			having count(#countField#) #countOperator# :#countParam#
		" );

		params[ countParam ] = { type="cf_sql_integer", value=arguments.value };
		StructAppend( params, subquery.params );

		return [ {
			  filter = obfuscateSqlForPreside( "exists (#subQuerySql#)" )
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
			, defaultValue = translateResource( "rules.dynamicExpressions:boolean.possesses" )
		);

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.oneToManyCount.label", data=[ relatedToTranslated, possesses, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:oneToManyCount.label", data=[ relatedToTranslated, possesses ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		, required string relatedTo
		, required string relationshipKey
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	){
		var objectBaseUri       = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToTranslated = translateObjectProperty( objectName, propertyName );
		var possesses           = translateResource(
			  uri          = objectBaseUri & "field.#propertyName#.possesses.truthy"
			, defaultValue = translateResource( "rules.dynamicExpressions:boolean.possesses" )
		);

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.oneToManyCount.text", data=[ relatedToTranslated, possesses, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:oneToManyCount.text", data=[ relatedToTranslated, possesses ] );
	}

}