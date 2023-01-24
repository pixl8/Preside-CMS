/**
 * Proxy expression executor for use with
 * auto-generated rules using relationship properties
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  parentObjectName
		, required string  parentPropertyName
		, required string  parentRelationship
		, required string  originalFilterHandler
		, required string  objectName
		, required string  propertyName
	) {
		return presideObjectService.dataExists(
			  objectName   = arguments.parentObjectName
			, id           = payload[ arguments.parentObjectName ].id ?: ""
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string  parentObjectName
		, required string  parentPropertyName
		, required string  parentRelationship
		, required string  originalFilterHandler
		, required string  objectName
		, required string  propertyName
	){
		var relationshipJoinArgs = _getArgsForRelationshipType( argumentCollection=arguments );

		relationshipJoinArgs.extraFilters = relationshipJoinArgs.extraFilter ?: [];
		ArrayAppend( relationshipJoinArgs.extraFilters, _getRelatedPropertyFilters( argumentCollection=arguments ), true );

		var subQuery  = presideObjectService.selectData(
			  argumentCollection  = relationshipJoinArgs
			, objectName          = arguments.objectName
			, selectFields        = [ "1" ]
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		return [ {
			  filter = obfuscateSqlForPreside( "exists (#subquery.sql#)" )
			, filterParams = subQuery.params
		}];
	}

// HELPERS
	private array function _getRelatedPropertyFilters() {
		var args = StructCopy( arguments );
		for( var ignore in [ "event", "rc", "prc", "parentObjectName", "parentPropertyName", "parentRelationship", "originalFilterHandler", "filterprefix" ] ) {
			StructDelete( args, ignore );
		}
		return runEvent(
			  event          = arguments.originalFilterHandler
			, eventArguments = args
			, private        = true
			, prepostExempt  = true
		);
	}

	private struct function _getArgsForRelationshipType() {
		switch( arguments.parentRelationship ) {
			case "many-to-one":
				return _getOuterJoinForManyToOne( argumentCollection=arguments );
			case "one-to-many":
				return _getOuterJoinForOneToMany( argumentCollection=arguments );
			case "many-to-many":
				return _getFilterJoinsForManyToMany( argumentCollection=arguments );
		}
	}

	private struct function _getOuterJoinForManyToOne() {
		var idField    = presideObjectService.getIdField( arguments.objectName );
		var innerField = "#arguments.objectName#.#idField#";
		var outerField = "#arguments.parentObjectName#.#arguments.parentPropertyName#";

		return { filter = obfuscateSqlForPreside( "#innerField# = #outerField#" ) };
	}

	private struct function _getOuterJoinForOneToMany() {
		var relationshipKey = presideObjectService.getObjectPropertyAttribute( objectName=arguments.parentObjectName, propertyName=arguments.parentPropertyName, attributeName="relationshipKey", defaultValue=arguments.parentObjectName );
		var idField = presideObjectService.getIdField( arguments.parentObjectName );
		var innerField = "#arguments.objectName#.#relationshipKey#";
		var outerField = "#arguments.parentObjectName#.#idField#";

		return { filter = obfuscateSqlForPreside( "#innerField# = #outerField#" ) };
	}

	private struct function _getFilterJoinsForManyToMany() {
		var idField    = presideObjectService.getIdField( arguments.parentObjectName );
		var outerField = "#arguments.parentObjectName#.#idField#";

		var prop       = presideObjectService.getObjectProperty( objectName=arguments.parentObjectName, propertyName=arguments.parentPropertyName );
		var relatedVia = prop.relatedVia           ?: "";
		var outerFk    = "";

		if ( isTrue( prop.relationshipIsSource ?: true ) ) {
			outerFk = prop.relatedViaSourceFk ?: arguments.parentObjectName;
		} else {
			outerFk = prop.relatedViaTargetFk ?: arguments.parentObjectName;
		}
		var innerField = "#relatedVia#.#outerFk#"

		return {
			  filter     = "#innerField# = #obfuscateSqlForPreside( outerField )#"
			, forceJoins = "inner"
		};
	}
}