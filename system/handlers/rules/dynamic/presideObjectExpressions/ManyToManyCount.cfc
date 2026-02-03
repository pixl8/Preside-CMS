/**
 * Dynamic expression handler for checking the number
 * of records in a many-to-many relationship
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
		,          string  _numericOperator   = "eq"
		,          string  savedFilter        = ""
		,          numeric value              = 0
	){
		var params         = {};
		var propAttributes = presideObjectService.getObjectProperty( arguments.objectName, arguments.propertyName );
		var keyFk          = propAttributes.relationshipIsSource ? propAttributes.relatedViaSourceFk : propAttributes.relatedViaTargetFk;
		var valueFk        = propAttributes.relationshipIsSource ? propAttributes.relatedViaTargetFk : propAttributes.relatedViaSourceFk;
		var outerPk        = "#arguments.objectName#.#presideObjectService.getIdField( arguments.objectName )#";
		var subQuery       = {};
		var countOperator  = rulesEngineNumericOperatorToSqlOperator( arguments._numericOperator );
		var countParam     = "manyToManyCount" & CreateUUId().lCase().replace( "-", "", "all" );

		if ( Len( Trim( arguments.savedFilter ) ) ) {
			subquery  = presideObjectService.selectData(
				  objectName          = propAttributes.relatedTo
				, selectFields        = [ "1" ]
				, filter              = obfuscateSqlForPreside( "#propAttributes.relatedVia#.#keyfk# = #outerPk#" )
				, getSqlAndParamsOnly = true
				, formatSqlParams     = true
				, having              = "count(#keyfk#) #countOperator# :#countParam#"
				, extraFilters        = [ filterService.prepareFilter( propAttributes.relatedTo, arguments.savedFilter ) ]
				, extraJoins          = [ {
					  type             = "inner"
					, tableName        = presideObjectService.getTableName( propAttributes.relatedVia )
					, tableAlias       = propAttributes.relatedVia
					, tableColumn      = valueFk
					, joinToTable      = propAttributes.relatedTo
					, joinToColumn     = presideObjectService.getIdField( propAttributes.relatedTo )
				}]
			);
		} else {
			subquery  = presideObjectService.selectData(
				  objectName          = propAttributes.relatedVia
				, selectFields        = [ "1" ]
				, filter              = obfuscateSqlForPreside( "#keyfk# = #outerPk#" )
				, getSqlAndParamsOnly = true
				, formatSqlParams     = true
				, having              = "count(#keyfk#) #countOperator# :#countParam#"
			);
		}

		params[ countParam ] = { type="cf_sql_integer", value=arguments.value };
		StructAppend( params, subquery.params );

		return [ {
			  filter = obfuscateSqlForPreside( "exists (#subquery.sql#)" )
			, filterParams = params
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