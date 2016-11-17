/**
 * Service that provides logic for using rules engine conditions
 * as data filters.
 *
 * @autodoc        true
 * @presideService true
 * @singleton      true
 *
 */
component displayName="Rules Engine Filter Service" {

// CONSTRUCTOR
	/**
	 * @expressionService.inject rulesEngineExpressionService
	 *
	 */
	public any function init( required any expressionService ) {
		_setExpressionService( arguments.expressionService );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Prepares a preside object filter based on the passed
	 * object name and configured
	 * set of rules engine expressions (i.e. a condition)
	 *
	 * @autodoc              true
	 * @objectName.hint      The name of the object that the filter is for
	 * @expressionArray.hint Cofigured expression array of the condition to prepare a filter for
	 *
	 */
	public struct function prepareFilter(
		  required string objectName
		, required array  expressionArray
	) {
		var dbAdapter = $getPresideObjectService().getDbAdapterForObject( arguments.objectName );
		var join      = "";
		var sql       = "";
		var params    = {};

		for( var i=1; i <= expressionArray.len(); i++ ) {
			var isJoin = !(i mod 2);
			if ( isJoin ) {
				join = expressionArray[i] == "and" ? "and" : "or";
			} else if ( IsArray( expressionArray[i] ) ) {
				var subFilter = prepareFilter( objectName, expressionArray[i] );

				sql &= " #join# ( #subfilter.filter# )";
				params.append( subFilter.filterParams );
			} else {
				var rawFilters = _getExpressionService().prepareExpressionFilters(
					  expressionId     = expressionArray[i].expression ?: ""
					, configuredFields = expressionArray[i].fields     ?: {}
					, objectName       = arguments.objectName
				);

				if ( rawFilters.len() ) {
					sql &= " #join# ";
					if ( rawFilters.len() > 1 ) {
						sql &= "( ";
					}
					var delim = "";
					for( var rawFilter in rawFilters ) {
						params.append( IsStruct( rawFilter.filter ?: "" ) ? rawFilter.filter : ( rawFilter.filterParams ?: {} ) );
						var rawSql = dbAdapter.getClauseSql( filter=rawFilter.filter ?: "", tableAlias=arguments.objectName );
						sql &= delim & Trim( Trim( rawSql ).reReplace( "^where", "" ) );
						delim = " and ";
					}
					if ( rawFilters.len() > 1 ) {
						sql &= " )";
					}
				}
			}
		}

		return {
			  filter       = Trim( sql )
			, filterParams = params
		};
	}

	/**
	 * Selects data from the given object and filtering
	 * by the expression array (rules engine condition).
	 * All extra arguments will be passed on to the [[api-presideobjectservice]]
	 * [[presideobjectservice-selectdata]] method.
	 *
	 * @autodoc              true
	 * @objectName.hint      The name of the object to select data from
	 * @expressionArray.hint Cofigured expression array of the condition to prepare a filter for
	 */
	public query function selectData(
		  required string objectName
		, required array  expressionArray
	) {
		var args = Duplicate( arguments );

		args.extraFilters = args.extraFilters ?: [];
		args.extraFilters.append( prepareFilter(
			  objectName      = arguments.objectName
			, expressionArray = arguments.expressionArray
		) );
		args.groupby = args.groupBy ?: "#objectName#.id";

		args.delete( "expressionArray" );

		return $getPresideObjectService().selectData( argumentCollection=args );
	}

	/**
	 * Returns the number of records that match the given
	 * expression array for the given object
	 *
	 * @autodoc              true
	 * @objectName.hint      The name of the object to get a count of records from
	 * @expressionArray.hint Cofigured expression array of the condition to prepare a filter for
	 */
	public numeric function getMatchingRecordCount(
		  required string objectName
		, required array  expressionArray
	) {
		var args = Duplicate( arguments );
		args.selectFields = [ "Count(1) as record_count" ];

		var result = selectData( argumentCollection=args );

		return Val( result.record_count );
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getExpressionService() {
		return _expressionService;
	}
	private void function _setExpressionService( required any expressionService ) {
		_expressionService = arguments.expressionService;
	}

}