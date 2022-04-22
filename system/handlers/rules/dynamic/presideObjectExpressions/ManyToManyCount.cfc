/**
 * Dynamic expression handler for checking the number
 * of records in a many-to-many relationship
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
		,          string  _numericOperator = "eq"
		,          string  savedFilter      = ""
		,          numeric value            = 0
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
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          string  filterPrefix = ""
		,          string  _numericOperator = "eq"
		,          string  savedFilter      = ""
		,          numeric value            = 0
	){
		var prefix               = Len( arguments.filterPrefix ) ? arguments.filterPrefix : ( Len( arguments.parentPropertyName ) ? arguments.parentPropertyName : arguments.objectName );
		var params               = {};
		var subQueryExtraFilters = [];
		var propAttributes       = presideObjectService.getObjectProperty( arguments.objectName, arguments.propertyName );
		var keyFk                = propAttributes.relationshipIsSource ? propAttributes.relatedViaSourceFk : propAttributes.relatedViaTargetFk;
		var valueFk              = propAttributes.relationshipIsSource ? propAttributes.relatedViaTargetFk : propAttributes.relatedViaSourceFk;
		var outerPk              = "#prefix#.#presideObjectService.getIdField( arguments.objectName )#";

		if ( Len( Trim( arguments.savedFilter ) ) ) {
			ArrayAppend( subQueryExtraFilters, getExistsFilterForEntityMatchingFilters(
				  objectName  = propAttributes.relatedTo
				, savedFilter = arguments.savedFilter
				, outerTable  = propAttributes.relatedVia
				, outerKey    = valueFk
			) );
		}
		for( var extraFilter in subQueryExtraFilters ) {
			StructAppend( params, extraFilter.filterParams ?: {} );
		}

		var countOperator = rulesEngineNumericOperatorToSqlOperator( arguments._numericOperator );
		var countParam = "manyToManyCount" & CreateUUId().lCase().replace( "-", "", "all" );
		var subquery  = presideObjectService.selectData(
			  objectName          = propAttributes.relatedVia
			, selectFields        = [ "1" ]
			, filter              = obfuscateSqlForPreside( "#keyfk# = #outerPk#" )
			, extraFilters        = subQueryExtraFilters
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
			, having              = "count(#keyfk#) #countOperator# :#countParam#"
		);

		params[ countParam ] = { type="cf_sql_integer", value=arguments.value };
		StructAppend( params, subquery.params );

		return [ {
			  filter = obfuscateSqlForPreside( "exists (#subquery.sql#)" )
			, filterParams = params
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
		var objectNameTranslated = translateResource( objectBaseUri & "title.singular", objectName );
		var relatedToTranslated = translateObjectProperty( objectName, propertyName );
		var possesses            = translateResource(
			  uri          = objectBaseUri & "field.#propertyName#.possesses.truthy"
			, defaultValue = translateResource( "rules.dynamicExpressions:boolean.possesses" )
		);

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.manyToManyCount.label", data=[ objectNameTranslated, relatedToTranslated, parentPropNameTranslated, possesses ] );
		}

		return translateResource( uri="rules.dynamicExpressions:manyToManyCount.label", data=[ objectNameTranslated, relatedToTranslated, possesses ] );
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
		var possesses            = translateResource(
			  uri          = objectBaseUri & "field.#propertyName#.possesses.truthy"
			, defaultValue = translateResource( "rules.dynamicExpressions:boolean.possesses" )
		);

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.manyToManyCount.text", data=[ objectNameTranslated, relatedToTranslated, parentPropNameTranslated, possesses ] );
		}

		return translateResource( uri="rules.dynamicExpressions:manyToManyCount.text", data=[ objectNameTranslated, relatedToTranslated, possesses ] );
	}

}