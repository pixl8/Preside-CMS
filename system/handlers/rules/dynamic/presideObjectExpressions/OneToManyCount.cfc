/**
 * Dynamic expression handler for checking the number
 * of records in a one-to-many relationship
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
		, required string  relatedTo
		, required string  relationshipKey
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
		,          string  savedFilter        = ""
		,          string  _numericOperator   = "eq"
		,          numeric value              = 0
	){
		var prefix               = Len( arguments.filterPrefix ) ? arguments.filterPrefix : ( Len( arguments.parentPropertyName ) ? arguments.parentPropertyName : arguments.objectName );
		var hasParent            = Len( arguments.parentObjectName ) && Len( arguments.parentPropertyName );
		var params               = {};
		var subQueryExtraFilters = [];

		if ( Len( Trim( arguments.savedFilter ) ) ) {
			ArrayAppend( subQueryExtraFilters, filterService.prepareFilter( arguments.relatedTo, arguments.savedFilter ) );
		}
		for( var extraFilter in subQueryExtraFilters ) {
			StructAppend( params, extraFilter.filterParams ?: {} );
		}

		var outerPk       = hasParent ? "#arguments.parentObjectName#.#arguments.parentPropertyName#" : "#prefix#.#presideObjectService.getIdField( arguments.objectName )#";
		var countOperator = rulesEngineNumericOperatorToSqlOperator( arguments._numericOperator );
		var countParam    = "oneToManyCount" & CreateUUId().lCase().replace( "-", "", "all" );
		var countField    = "#arguments.relatedTo#.#relationshipKey#";
		var subquery      = presideObjectService.selectData(
			  objectName          = arguments.relatedTo
			, selectFields        = [ "1" ]
			, filter              = obfuscateSqlForPreside( "#arguments.relatedTo#.#arguments.relationshipKey# = #outerPk#" )
			, extraFilters        = subQueryExtraFilters
			, having              = "count(#countField#) #countOperator# :#countParam#"
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
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