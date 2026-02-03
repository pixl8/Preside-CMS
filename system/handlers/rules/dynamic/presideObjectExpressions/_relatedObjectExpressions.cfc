/**
 * Proxy expression executor for use with
 * auto-generated rules using relationship properties
 *
 * @feature rulesEngine
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string parentObjectName
		, required string parentPropertyName
		, required array  relationshipHelpers
		, required string originalFilterHandler
		, required string objectName
		, required string propertyName
	) {
		return presideObjectService.dataExists(
			  objectName   = arguments.parentObjectName
			, id           = payload[ arguments.parentObjectName ].id ?: ""
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string parentObjectName
		, required string parentPropertyName
		, required array  relationshipHelpers
		, required string originalFilterHandler
		, required string objectName
		, required string propertyName
	){
		var filter = "";
		var params = {};

		for( var i=ArrayLen( arguments.relationshipHelpers ); i>0; i-- ) {
			var filterArgs = StructCopy( arguments.relationshipHelpers[ i ].filterArgs );

			if ( !Len( filter ) ) {
				filterArgs.extraFilters = _getRelatedPropertyFilters( argumentCollection=arguments );
			} else {
				filterArgs.extraFilters = [ { filter=filter } ];
			}

			var subQuery  = presideObjectService.selectData(
				  argumentCollection  = filterArgs
				, objectName          = arguments.relationshipHelpers[ i ].objectName
				, selectFields        = [ "1" ]
				, getSqlAndParamsOnly = true
				, formatSqlParams     = true
			);

			filter = "exists (#obfuscateSqlForPreside( subQuery.sql )#)";
			StructAppend( params, subQuery.params );
		}

		return [ {
			  filter       = filter
			, filterParams = params
		}];
	}

// HELPERS
	private array function _getRelatedPropertyFilters() {
		var args = StructCopy( arguments );
		for( var ignore in [ "event", "rc", "prc", "parentObjectName", "parentPropertyName", "relationshipHelpers", "originalFilterHandler", "filterprefix" ] ) {
			StructDelete( args, ignore );
		}
		return runEvent(
			  event          = arguments.originalFilterHandler
			, eventArguments = args
			, private        = true
			, prepostExempt  = true
		);
	}


}