/**
 * Dynamic expression handler for checking outdated translations of multi-lingual object records
 *
 * @feature rulesEngine
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          boolean _possesses = true
		,          string  value      = ""
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
	){

		var exists = arguments._possesses ? "exists" : "not exists";

		var objDateModField = presideObjectService.getDateModifiedField( objectName=arguments.objectName );
		var relDateModField = presideObjectService.getDateModifiedField( objectName=arguments.relatedTo );

		var outerPk   = "#arguments.objectName#.#presideObjectService.getIdField( arguments.objectName )#";
		var paramName = "outdatedTranslation" & createUUId().lCase().replace( "-", "", "all" );
		var filter    = "#arguments.relatedTo#.#arguments.relationshipKey# = #outerPk# and #arguments.relatedTo#._translation_language in (:#paramName#) and #arguments.objectName#.#objDateModField# > #arguments.relatedTo#.#relDateModField#";

		var subquery  = presideObjectService.selectData(
			  objectName          = arguments.relatedTo
			, selectFields        = [ "1" ]
			, filter              = obfuscateSqlForPreside( filter )
			, filterParams        = { "#paramName#" = { type="cf_sql_varchar", value=arguments.value, list=true } }
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		return [ {
			  filter = obfuscateSqlForPreside( "#exists# (#subquery.sql#)" )
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
			, defaultValue = translateResource( "rules.dynamicExpressions:boolean.possesses.with.negative" )
		);

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.outdatedTranslation.label", data=[ relatedToTranslated, possesses, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:outdatedTranslation.label", data=[ relatedToTranslated, possesses ] );
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
			return translateResource( uri="rules.dynamicExpressions:related.outdatedTranslation.text", data=[ relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:outdatedTranslation.text", data=[ relatedToTranslated ] );
	}

}