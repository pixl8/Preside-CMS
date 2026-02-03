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
		, required string  relatedVia
		, required string  relatedViaSourceFk
		, required string  relatedViaTargetFk
		, required string  relationshipIsSource
		,          boolean _possesses = true
		,          string  value      = ""
	){
		var paramName = "manyToManyMatch" & CreateUUId().lCase().replace( "-", "", "all" );
		var isSource  = !IsBoolean( arguments.relationshipIsSource ) || arguments.relationshipIsSource;
		var valueFk   = isSource ? arguments.relatedViaTargetFk : arguments.relatedViaSourceFk;
		var keyFk     = isSource ? arguments.relatedViaSourceFk : arguments.relatedViaTargetFk;
		var outerPk   = "#arguments.objectName#.#presideObjectService.getIdField( arguments.objectName )#";
		var exists    = arguments._possesses ? "exists" : "not exists";
		var subquery  = presideObjectService.selectData(
			  objectName          = arguments.relatedVia
			, selectFields        = [ "1" ]
			, filter              = obfuscateSqlForPreside( "#keyfk# = #outerPk# and #valuefk# in (:#paramName#)" )
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
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	) {
		var objectBaseUri        = presideObjectService.getResourceBundleUriRoot( objectName );
		var objectNameTranslated = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated  = translateObjectProperty( objectName, propertyName );
		var possesses            = translateResource(
			  uri          = objectBaseUri & "field.#propertyName#.possesses.truthy"
			, defaultValue = translateResource( "rules.dynamicExpressions:boolean.possesses" )
		);

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.manyToManyMatch.label", data=[ objectNameTranslated, relatedToTranslated, parentPropNameTranslated, possesses ] );
		}

		return translateResource( uri="rules.dynamicExpressions:manyToManyMatch.label", data=[ objectNameTranslated, relatedToTranslated, possesses ] );
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
			return translateResource( uri="rules.dynamicExpressions:related.manyToManyMatch.text", data=[ objectNameTranslated, relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:manyToManyMatch.text", data=[ objectNameTranslated, relatedToTranslated ] );
	}

}