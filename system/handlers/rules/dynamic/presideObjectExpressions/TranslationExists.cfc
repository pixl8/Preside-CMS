/**
 * Dynamic expression handler for checking if translations of multi-lingual object records in given languages exist
 *
 * @feature rulesEngine and multilingual
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";
	property name="filterService"        inject="rulesEngineFilterService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          boolean _possesses  = true
		,          string  value       = ""
		,          string  savedFilter = ""
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
		,          boolean _possesses = true
		,          string  value      = ""
		,          string  savedFilter = ""
	){

		var subQueryExtraFilters = [];
		var params               = {};
		var exists               = arguments._possesses ? "exists" : "not exists";

		if ( Len( Trim( arguments.savedFilter ) ) ) {
			arrayAppend( subQueryExtraFilters, filterService.prepareFilter( arguments.relatedTo, arguments.savedFilter ) );
		}
		for ( var extraFilter in subQueryExtraFilters ) {
			structAppend( params, extraFilter.filterParams ?: {} );
		}

		var outerPk   = "#arguments.objectName#.#presideObjectService.getIdField( arguments.objectName )#";
		var paramName = "translationExists" & createUUId().lCase().replace( "-", "", "all" );
		var filter    = "#arguments.relatedTo#.#arguments.relationshipKey# = #outerPk# and #arguments.relatedTo#._translation_language in (:#paramName#)";

		var subquery  = presideObjectService.selectData(
			  objectName          = arguments.relatedTo
			, selectFields        = [ "1" ]
			, filter              = obfuscateSqlForPreside( filter )
			, filterParams        = { "#paramName#" = { type="cf_sql_varchar", value=arguments.value, list=true } }
			, extraFilters        = subQueryExtraFilters
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		structAppend( params, subquery.params );

		return [ {
			  filter = obfuscateSqlForPreside( "#exists# (#subquery.sql#)" )
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
			return translateResource( uri="rules.dynamicExpressions:related.translationExists.label", data=[ relatedToTranslated, possesses, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:translationExists.label", data=[ relatedToTranslated, possesses ] );
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
			return translateResource( uri="rules.dynamicExpressions:related.translationExists.text", data=[ relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:translationExists.text", data=[ relatedToTranslated ] );
	}

}