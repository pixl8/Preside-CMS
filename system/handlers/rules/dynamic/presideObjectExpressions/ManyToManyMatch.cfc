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
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          boolean _possesses = true
		,          string  value      = ""
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
		, required string  relatedVia
		, required string  relatedViaSourceFk
		, required string  relatedViaTargetFk
		, required string  relationshipIsSource
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          string  filterPrefix = ""
		,          boolean _possesses = true
		,          string  value      = ""
	){
		var paramName     = "manyToManyMatch" & CreateUUId().lCase().replace( "-", "", "all" );
		var defaultPrefix = parentPropertyName.len() ? "#parentPropertyName#$#propertyName#" : propertyName;
		var prefix        = filterPrefix.len() ? ( filterPrefix & "$#propertyName#" ) : defaultPrefix;
		var idField       = presideObjectService.getIdField( relatedTo );

		if ( _possesses ) {
			var filterSql = "#prefix#.#idField# in (:#paramName#)";
			var params    = { "#paramName#" = { value=arguments.value, type="cf_sql_varchar", list=true } };

			return [ { filter=filterSql, filterParams=params } ];
		}

		var params        = {};
		var subQueryAlias = paramName;
		var subQuery      = presideObjectService.selectData(
			  objectName          = arguments.relatedVia
			, selectFields        = [ "#( relationshipIsSource ? relatedViaSourceFk : relatedViaTargetFk )# as id" ]
			, forceJoins          = "inner"
			, getSqlAndParamsOnly = true
			, filter              = { "#( relationshipIsSource ? relatedViaTargetFk : relatedViaSourceFk )#" = listToArray( arguments.value ) }
		);

		for( var param in subQuery.params ) {
			params[ param.name ] = param;
			params[ param.name ].delete( "name" );
		}

		return [ {
			  filter = "#subQueryAlias#.id is null"
			, filterParams = params
			, extraJoins = [{
				  type           = "left"
				, subQuery       = subQuery.sql
				, subQueryAlias  = subQueryAlias
				, subQueryColumn = "id"
				, joinToTable    = objectName
				, joinToColumn   = presideObjectService.getIdField( objectName )
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
		var objectBaseUri        = presideObjectService.getResourceBundleUriRoot( objectName );
		var relatedToBaseUri     = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var objectNameTranslated = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated  = translateResource( relatedToBaseUri & "title", relatedTo );
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
		var relatedToBaseUri     = presideObjectService.getResourceBundleUriRoot( relatedTo );
		var objectNameTranslated = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated  = translateResource( relatedToBaseUri & "title", relatedTo );


		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.manyToManyMatch.text", data=[ objectNameTranslated, relatedToTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:manyToManyMatch.text", data=[ objectNameTranslated, relatedToTranslated ] );
	}

}