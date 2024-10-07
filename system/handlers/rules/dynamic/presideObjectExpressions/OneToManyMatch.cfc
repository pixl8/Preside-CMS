/**
 * Dynamic expression handler for checking whether or not a preside object
 * many-to-many relationships match the selected related records
 *
 * @feature rulesEngine
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
		, required string  relationshipKey
		,          boolean _is   = true
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
		, required string  relationshipKey
		,          boolean _is                = true
		,          string  value              = ""
	){
		var paramName = "oneToManyMatch" & CreateUUId().lCase().replace( "-", "", "all" );
		var valuePk   = presideObjectService.getIdField( arguments.relatedto );
		var subquery  = presideObjectService.selectData(
			  objectName          = arguments.relatedTo
			, selectFields        = [ valuePk, arguments.relationshipKey ]
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		var dbAdapter          = getPresideObject( arguments.objectName ).getDbAdapter();
		var subQueryAlias      = dbAdapter.escapeEntity( "subquery_#arguments.relatedTo#" );
		var idField            = presideObjectService.getIdField( arguments.objectName );
		var idFieldEscapedFull = dbAdapter.escapeEntity( "#arguments.objectName#.#idField#" );
		var exists             = arguments._is ? "exists" : "not exists";
		var subQuerySql        = obfuscateSqlForPreside( "
			select 1
			from (#subQuery.sql#) as #subQueryAlias#
			where #idFieldEscapedFull# = #subQueryAlias#.#arguments.relationshipKey#
			and #subQueryAlias#.#valuePk# in (:#paramName#)
		" );

		subquery.params[ paramName ] = { type="cf_sql_varchar", value=arguments.value, list=true };

		return [ {
			  filter = obfuscateSqlForPreside( "#exists# (#subquerySql#)" )
			, filterParams = subquery.params
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
			return translateResource( uri="rules.dynamicExpressions:related.oneToManyMatch.label", data=[ relatedToTranslated, possesses, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:oneToManyMatch.label", data=[ relatedToTranslated, possesses ] );
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
			return translateResource( uri="rules.dynamicExpressions:related.oneToManyMatch.text", data=[ relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:oneToManyMatch.text", data=[ relatedToTranslated ] );
	}

}