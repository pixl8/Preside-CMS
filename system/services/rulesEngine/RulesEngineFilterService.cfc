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
	 * @filterId.hint        ID of the saved filter (from rules_engine_condition object) to prepare filters for. Not required if using expressionArray
	 * @expressionArray.hint Configured expression array of the condition to prepare a filter for. Not required if using filterId.
	 * @filterPrefix.hint    An optional prefix to prepend to any property filters. This is useful when you are traversing the relationship tree and building filters within filters!
	 *
	 */
	public struct function prepareFilter(
		  required string objectName
		,          string filterId        = ""
		,          array  expressionArray = getExpressionArrayForSavedFilter( arguments.filterId )
		,          string filterPrefix    = ""
	) {
		var dbAdapter  = $getPresideObjectService().getDbAdapterForObject( arguments.objectName );
		var join       = "";
		var sql        = "";
		var params     = {};
		var extraJoins = [];
		var isHaving   = false;

		for( var i=1; i <= expressionArray.len(); i++ ) {
			var isJoin = !(i mod 2);
			if ( isJoin ) {
				join = expressionArray[i] == "and" ? "and" : "or";
			} else if ( IsArray( expressionArray[i] ) ) {
				var subFilter = prepareFilter( objectName=objectName, expressionArray=expressionArray[i], filterPrefix=arguments.filterPrefix );

				if ( StructKeyExists( subFilter, "having" ) ) {
					isHaving = true;
					sql &= " #join# #subfilter.having#";
				} else {
					sql &= " #join# #subfilter.filter#";
				}

				params.append( subFilter.filterParams );
				extraJoins.append( subFilter.extraJoins, true );
			} else {
				var rawFilters = _getExpressionService().prepareExpressionFilters(
					  expressionId     = expressionArray[i].expression ?: ""
					, configuredFields = expressionArray[i].fields     ?: {}
					, objectName       = arguments.objectName
					, filterPrefix     = arguments.filterPrefix
				);

				if ( rawFilters.len() ) {
					sql &= " #join# ";
					if ( rawFilters.len() > 1 ) {
						sql &= "( ";
					}
					var delim = "";
					for( var rawFilter in rawFilters ) {
						extraJoins.append( rawFilter.extraJoins ?: [], true );
						params.append( rawFilter.filterParams ?: {} );
						if ( IsStruct( rawFilter.filter ?: "" ) ){
							params.append( rawFilter.filter );
						}

						var rawSql = dbAdapter.getClauseSql( filter=rawFilter.filter ?: "", tableAlias=arguments.objectName );
						var having = rawFilter.having ?: "";

						if ( having.len() ) {
							isHaving = true;
							if ( rawSql.len() ) {
								rawSql = "( #rawSql# and #having# )";
							} else {
								rawSql = having;
							}
						}

						if ( rawSql.len() ) {
							sql &= delim & Trim( Trim( rawSql ).reReplace( "^where", "" ) );
							delim = " and ";
						}
					}
					if ( rawFilters.len() > 1 ) {
						sql &= " )";
					}
				}
			}
		}

		if ( sql.trim().len() ) {
			sql = "( #sql.trim()# )";
		}

		var returnValue = { filterParams=params, extraJoins=extraJoins };

		if ( isHaving ) {
			returnValue.having = Trim( sql );
		} else {
			returnValue.filter = Trim( sql );
		}

		return returnValue;
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
	public any function selectData(
		  required string objectName
		, required array  expressionArray
	) {
		var args = Duplicate( arguments );

		args.extraFilters = args.extraFilters ?: [];
		args.extraFilters.append( prepareFilter(
			  objectName      = arguments.objectName
			, expressionArray = arguments.expressionArray
		) );
		args.autoGroupBy = true;
		args.distinct    = true;

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
		return selectData( argumentCollection=arguments, recordCountOnly=true );
	}

	/**
	 * Returns an expression array for a saved filter id
	 *
	 * @autodoc
	 * @filterId.hint ID of the saved filter
	 */
	public array function getExpressionArrayForSavedFilter( required string filterId ) {
		var filterRecord = $getPresideObject( "rules_engine_condition" ).selectData(
			  id           = arguments.filterId
			, selectFields = [ "expressions" ]
		);

		try {
			var expressionArray = DeSerializeJson( filterRecord.expressions );
			if ( IsArray( expressionArray ) ) {
				return expressionArray;
			}
		} catch ( any e ) {}

		return [];
	}

	public query function getFavourites( required string objectName ) {
		return $getPresideObject( "rules_engine_condition" ).selectData(
			  selectFields = [ "id", "condition_name" ]
			, filter       = { filter_object=arguments.objectName, is_favourite=true }
			, orderBy      = "condition_name"
		);
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