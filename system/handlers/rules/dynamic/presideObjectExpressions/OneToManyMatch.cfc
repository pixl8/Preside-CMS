/**
 * Dynamic expression handler for checking whether or not a preside object
 * many-to-many relationships match the selected related records
 *
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
		, required string  relationshipKey
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          boolean _is   = true
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
		, required string  relationshipKey
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
		,          boolean _is                = true
		,          string  value              = ""
	){
		var prefix    = Len( arguments.filterPrefix ) ? arguments.filterPrefix : ( Len( arguments.parentPropertyName ) ? arguments.parentPropertyName : arguments.objectName );
		var hasParent = Len( arguments.parentObjectName ) && Len( arguments.parentPropertyName );
		var paramName = "oneToManyMatch" & CreateUUId().lCase().replace( "-", "", "all" );
		var valuePk   = presideObjectService.getIdField( arguments.relatedto );
		var outerPk   = hasParent ? "#arguments.parentObjectName#.#arguments.parentPropertyName#" : "#prefix#.#presideObjectService.getIdField( arguments.objectName )#";
		var exists    = arguments._is ? "exists" : "not exists";
		var subquery  = presideObjectService.selectData(
			  objectName          = arguments.relatedTo
			, selectFields        = [ "1" ]
			, filter              = obfuscateSqlForPreside( "#arguments.relationshipKey# = #outerPk# and #arguments.relatedTo#.#valuePk# in (:#paramName#)" )
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
		  required string  objectName
		, required string  propertyName
		, required string  relatedTo
		, required string  relationshipKey
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
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
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
	){
		var relatedToTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.oneToManyMatch.text", data=[ relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:oneToManyMatch.text", data=[ relatedToTranslated ] );
	}

}