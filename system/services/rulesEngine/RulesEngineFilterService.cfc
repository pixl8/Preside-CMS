/**
 * Service that provides logic for using rules engine conditions
 * as data filters.
 *
 * @autodoc        true
 * @presideService true
 * @singleton      true
 * @feature        rulesEngine
 */
component displayName="Rules Engine Filter Service" {

// CONSTRUCTOR
	/**
	 * @expressionService.inject rulesEngineExpressionService
	 * @tenancyService.inject    tenancyService
	 */
	public any function init(
		  required any expressionService
		, required any tenancyService
	) {
		_setExpressionService( arguments.expressionService );
		_setTenancyService( arguments.tenancyService );

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
	 *
	 */
	public struct function prepareFilter(
		  required string  objectName
		,          string  filterId           = ""
		,          array   expressionArray
		,          boolean ignoreSegmentation = false
	) {
		if ( Len( arguments.filterId ) && isSegmentationFilter( arguments.filterId ) && !arguments.ignoreSegmentation ) {
			return prepareSegmentationFilter( arguments.objectName, arguments.filterId );
		}

		arguments.expressionArray = arguments.expressionArray ?: getExpressionArrayForSavedFilter( arguments.filterId );

		var dbAdapter  = $getPresideObjectService().getDbAdapterForObject( arguments.objectName );
		var join       = "";
		var sql        = "";
		var params     = {};
		var extraJoins = [];
		var isHaving   = false;
		var havingSql  = "";
		var havingfields = [];

		for( var i=1; i <= ArrayLen( expressionArray ); i++ ) {
			var isJoin = !(i mod 2);
			if ( isJoin ) {
				if ( Len( Trim( sql ) ) ) {
					join = expressionArray[i] == "and" ? "and" : "or";
				}
			} else if ( IsArray( expressionArray[i] ) ) {
				var subFilter = prepareFilter( objectName=objectName, expressionArray=expressionArray[i] );

				if ( StructKeyExists( subFilter, "having" ) ) {
					isHaving = true;
					sql &= " #join# #subfilter.having#";
				} else {
					sql &= " #join# #subfilter.filter#";
				}

				StructAppend( params, subFilter.filterParams );
				ArrayAppend( extraJoins, subFilter.extraJoins, true );
			} else {
				var rawFilters = _getExpressionService().prepareExpressionFilters(
					  expressionId     = expressionArray[i].expression ?: ""
					, configuredFields = expressionArray[i].fields     ?: {}
					, objectName       = arguments.objectName
				);
				var rawFilterCount = ArrayLen( rawFilters );

				if ( rawFilterCount ) {
					sql &= " #join# ";
					if ( rawFilterCount > 1 ) {
						sql &= "( ";
					}
					var delim = "";
					for( var rawFilter in rawFilters ) {
						ArrayAppend( extraJoins, rawFilter.extraJoins ?: [], true );
						StructAppend( params, rawFilter.filterParams ?: {} );
						if ( IsStruct( rawFilter.filter ?: "" ) ){
							StructAppend( params, rawFilter.filter );
						}

						var rawSql = dbAdapter.getClauseSql( filter=rawFilter.filter ?: "", tableAlias=arguments.objectName );
						if ( isEmpty( rawSql ) ) {
							rawSql = " 1 = 1 ";
						}
						var having = rawFilter.having ?: "";

						if ( Len( having ) ) {
							isHaving = true;
							if ( Len( havingSql ) ) {
								havingSql = "( #havingSql# and #having# )";
							} else {
								havingSql = having;
							}
						}

						if ( Len( rawSql ) ) {
							sql  &= delim & Trim( Trim( rawSql ).reReplace( "^where", "" ) );
							delim = " and ";

							var havingField = "";

							if ( Len( Trim( rawFilter.propertyName ?: "" ) ) ) {
								havingField = rawFilter.propertyName;
							} else {
								var firstField = ListFirst( Trim( Replace( Len( having ) ? having : ( IsStruct( rawFilter.filter ?: "" ) ? "" : rawFilter.filter ?: "" ), "(", "", "all" ) ), " " );
								if( ListLen( firstField, "." ) == 2 ) {
									havingField = firstField;
								}
							}

							if ( Len( havingField ) && !ArrayFindNoCase( havingfields, havingField ) ) {
								ArrayAppend( havingfields, havingField );
							}
						}
					}
					if ( rawFilterCount > 1 ) {
						sql &= " )";
					}
				}
			}
		}

		if ( Len( Trim( sql ) ) ) {
			sql = "( #Trim( sql )# )";
		}

		var returnValue = { filter=Trim( sql ), filterParams=params, extraJoins=extraJoins };

		if ( isHaving ) {
			returnValue.having       = havingSql;
			returnValue.havingfields = havingfields;
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
		  required string  objectName
		, required array   expressionArray
		,          boolean distinct      = true
		,          boolean forceDistinct = false
	) {
		var args = Duplicate( arguments );

		args.extraFilters = args.extraFilters ?: [];
		args.extraFilters.append( prepareFilter(
			  objectName      = arguments.objectName
			, expressionArray = arguments.expressionArray
		) );
		args.autoGroupBy = true;

		if ( args.distinct && !args.forceDistinct ) {
			args.distinct = false;
			for ( var extraFilter in args.extraFilters ) {
				for ( var extraJoin in extraFilter.extraJoins ?: [] ) {
					if ( Len( extraJoin.subQuery ?: "" ) ) {
						args.distinct = true;
						break;
					}
				}

				if ( args.distinct ) { break; }
			}
		}


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
		if ( !StructKeyExists( arguments, "selectFields" ) ) {
			var idField = $getPresideObjectService().getIdField( arguments.objectName );
			if ( Len( idField ) ) {
				arguments.selectFields = [ idField ];
			}
		}
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
			, filter       = "filter_object = :filter_object and is_favourite = :is_favourite and ( is_segmentation_filter is null or is_segmentation_filter = :is_segmentation_filter )"
			, filterParams = {
				  filter_object       = arguments.objectName
				, is_favourite        = true
				, is_segmentation_filter = false
			  }
			, extraFilters = [ _getFilterPermissionFilter() ]
			, forceJoins = "left"
			, orderBy = "condition_name"
			, autoGroupBy = true
		);
	}

	public query function getNonFavouriteFilters( required string objectName ) {
		return $getPresideObject( "rules_engine_condition" ).selectData(
			  selectFields = [ "rules_engine_condition.id", "rules_engine_condition.condition_name", "filter_folder.label as folder", "case when filter_folder.label is null then 0 else 1 end as has_folder" ]
			, filter       = "filter_object = :filter_object and ( is_favourite = :is_favourite or is_favourite is null ) and ( is_segmentation_filter is null or is_segmentation_filter = :is_segmentation_filter )"
			, filterParams = {
				  filter_object       = objectName
				, is_favourite        = false
				, is_segmentation_filter = false
			}
			, extraFilters = [ _getFilterPermissionFilter() ]
			, forceJoins  = "left"
			, orderBy     = "has_folder desc, filter_folder.label,condition_name"
			, autoGroupBy = true
		);
	}

	public array function getSegmentationFiltersForFavourites( required string objectName, parent="", depth=0 ) {
		var filters     = [];
		var filterQuery = $getPresideObject( "rules_engine_condition" ).selectData(
			  selectFields = [
			  	  "rules_engine_condition.id"
			  	, "rules_engine_condition.condition_name"
			  	, "rules_engine_condition.segmentation_last_count"
			  ]
			, filter = {
				  filter_object              = objectName
				, is_segmentation_filter     = true
				, parent_segmentation_filter = arguments.parent
			  }
		);

		for( var filter in filterQuery ) {
			if ( arguments.depth ) {
				filter.condition_name = RepeatString( "&nbsp;&rarr;&nbsp;", arguments.depth ) & filter.condition_name;
			}

			ArrayAppend( filters, filter );
			var children = getSegmentationFiltersForFavourites( arguments.objectName, filter.id, arguments.depth+1 );
			for( var child in children ) {
				ArrayAppend( filters, child );
			}
		}

		return filters;
	}

	public void function getRulesEngineSelectArgsForEdit( required struct args, string rulesEngineId = "" ) {
		var adminUserId = $getAdminLoggedInUserId();

		args.extraFilters = args.extraFilters ?: [];

		args.forceJoins = "left";

		if ( Len( rulesEngineId ) ) {
			args.extraFilters.append( {
				filter = { "rules_engine_condition.id" = arguments.rulesEngineId }
			} );
		}

		args.extraFilters.append( {
			  filter       = "( rules_engine_condition.owner is null or rules_engine_condition.owner=:owner or ( user_groups.id in (:user_groups.id) and rules_engine_condition.allow_group_edit = 1 ) )"
			, filterParams = {
				  owner            = adminUserId
				, "user_groups.id" = $getAdminPermissionService().listUserGroups( adminUserId )
			}
		} );
	}

	public boolean function filterIsUsed( required string filterId ) {
		return $getPresideObjectService().hasReferences( "rules_engine_condition", arguments.filterId );
	}


	public boolean function objectSupportsSegmentationFilters( required string objectName ) {
		// on by default if there is an idfield
		// can be turned off by setting @datamanagerUseSegmentationFilters false
		var idField         = $getPresideObjectService().getIdField( objectName=arguments.objectName );
		var useSegmentation = $getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerUseSegmentationFilters"
		);

		return Len( idField ) && (!IsBoolean( useSegmentation ) || useSegmentation );
	}

	public query function getSegmentationFilter( required string filterId ) {
		return $getPresideObject( "rules_engine_condition" ).selectData(
			  filter       = "id = :id and is_segmentation_filter = :is_segmentation_filter and filter_object is not null"
			, filterParams = { id=arguments.filterId, is_segmentation_filter=true }
		);
	}

	public void function recalculateAllSegmentationFilters( string parentId="" ) {
		var filters = $getPresideObject( "rules_engine_condition" ).selectData(
			  filter = { is_segmentation_filter=true, parent_segmentation_filter=arguments.parentId }
		);

		for( var filter in filters ) {
			if ( !objectSupportsSegmentationFilters( filter.filter_object ) ) {
				continue;
			}

			if ( IsDate( filter.segmentation_next_calculation ) && Now() >= filter.segmentation_next_calculation ) {
				recalculateSegmentationFilterData( filterId=filter.id, recalculateChildren=true );
			} else {
				recalculateAllSegmentationFilters( parentId=filter.id );
			}
		}
	}

	public void function recalculateSegmentationFilterData(
		  required string  filterId
		,          boolean recalculateChildren = true
		,          boolean isFirstEntry = true
		,          any     logger
	) {
		var start    = GetTickCount();
		var canLog   = StructKeyExists( arguments, "logger" );
		var canInfo  = canLog && arguments.logger.canInfo();
		var canWarn  = canLog && arguments.logger.canWarn();
		var canError = canLog && arguments.logger.canError();
		var filter   = getSegmentationFilter( arguments.filterId )

		if ( !filter.recordCount ) {
			if ( canWarn ) {
				arguments.logger.warn( $translateResource(
					  uri  = "cms:datamanager.managefilters.segmentation.recalculation.log.not.found.warning"
					, data = [ arguments.filterId ]
				) );
			}

			return;
		}

		var filterLabel = $renderLabel( "rules_engine_condition", arguments.filterId );
		if ( canInfo ) {
			arguments.logger.info( $translateResource(
				  uri = "cms:datamanager.managefilters.segmentation.recalculation.log.start.for.record"
				, data = [ filterLabel ]
			) );
		}

		var holdingId    = CreateUUId();
		var totalRecords = _flattenSegmentationFilterToHoldingTable( holdingId, filter );

		_addNewlyApplicableSegmentationRecords( holdingId, arguments.filterId, filter.filter_object );
		_removeNoLongerApplicableSegmentationRecords( holdingId, arguments.filterId, filter.filter_object );
		_clearHoldingTable( holdingId );

		$getPresideObject( "rules_engine_condition" ).updateData( id=arguments.filterId, useVersioning=false, data={
			  segmentation_last_calculation = Now()
			, segmentation_last_count       = totalRecords
			, segmentation_last_time_taken  = GetTickCount()-start
			, segmentation_next_calculation = _calculateNextSegmentationCalculation( filter )
		} );

		if ( canInfo ) {
			arguments.logger.info( $translateResource(
				  uri = "cms:datamanager.managefilters.segmentation.recalculation.log.finish.for.record"
				, data = [ filterLabel, NumberFormat( totalRecords ) ]
			) );
		}

		if ( arguments.recalculateChildren )  {
			var children = $getPresideObject( "rules_engine_condition" ).selectData(
				  selectFields = [ "id" ]
				, filter       = { parent_segmentation_filter=arguments.filterId, is_segmentation_filter=true }
			);
			for( var child in children ) {
				recalculateSegmentationFilterData(
					  argumentCollection = arguments
					, filterId           = child.id
					, isFirstEntry       = false
				);
			}
		}

		if ( canInfo && arguments.isFirstEntry ) {
			arguments.logger.info( $translateResource( "cms:datamanager.managefilters.segmentation.recalculation.log.finish" ) );
			sleep( 3000 );
		}
	}

	public numeric function getSegmentationCount( required string filterId, required string objectName ) {
		return $getPresideObject( "rules_engine_filter_data" ).selectData(
			  filter          = { filter=arguments.filterId, object_name=arguments.objectName }
			, recordCountOnly = true
		);
	}

	public boolean function isSegmentionFilter( required string filterid ) {
		return isSegmentationFilter( arguments.filterId );
	}
	public boolean function isSegmentationFilter( required string filterid ) {
		return $getPresideObject( "rules_engine_condition" ).dataExists(
			  filter = { id=arguments.filterId, is_segmentation_filter=true }
		);
	}
	public boolean function hasAnySegmentationFilters( required string objectName ) {
		return $getPresideObject( "rules_engine_condition" ).dataExists( filter={
			  filter_object          = arguments.objectName
			, is_segmentation_filter = true
		} );
	}

	public struct function prepareSegmentationFilter(
		  required string objectName
		, required string filterId
	) {
		var adapter       = $getPresideObjectService().getDbAdapterForObject( "rules_engine_filter_data" );
		var flatTableName = adapter.escapeEntity( $getPresideObject( "rules_engine_filter_data" ).getTableName() );
		var paramPrefix   = Replace( LCase( CreateUUId() ), "-", "", "all" );
		var parentIdField = $getPresideObjectService().getIdField( arguments.objectName );
		var subQuery      = $helpers.obfuscateSqlForPreside(
			"select 1
			 from #flatTableName#
			 where #flatTableName#.#adapter.escapeEntity( "filter" )# = :#paramPrefix#filter
			 and #flatTableName#.#adapter.escapeEntity( "object_name" )# = :#paramPrefix#object_name
			 and #flatTableName#.#adapter.escapeEntity( "record_id" )# = #adapter.escapeEntity( "#arguments.objectName#.#parentIdField#" )#"
		);
		var params = {
			  "#paramPrefix#filter"      = { type="cf_sql_varchar", value=arguments.filterId }
			, "#paramPrefix#object_name" = { type="cf_sql_varchar", value=arguments.objectName }
		};

		return {
			  filter       = "exists (#subQuery#)"
			, filterParams = params
		}
	}

	public array function getLineageLabels( required string filterId ) {
		var filter = $getPresideObject( "rules_engine_condition" ).selectData(
			  id           = arguments.filterId
			, selectFields = [ "condition_name", "parent_segmentation_filter" ]
		);

		if ( !filter.recordCount ) {
			return [];
		}

		var labels = [ { id=arguments.filterId, label=filter.condition_name } ];

		if ( Len( filter.parent_segmentation_filter ) ) {
			ArrayAppend( labels, getLineageLabels( filter.parent_segmentation_filter ), true );
		}

		return labels;
	}

	public boolean function cloneFilterChildren(
		  required string sourceId
		, required string targetId
		,          any    logger
		,          any    progress
	){
		var canLog  = StructKeyExists( arguments, "logger" );
		var canInfo = canLog && arguments.logger.canInfo();
		var sourceLabel = "";
		var targetLabel = "";
		var dao = $getPresideObject( "rules_engine_condition" );

		if ( canInfo ) {
			sourceLabel = $renderLabel( "rules_engine_condition", arguments.sourceId );
			targetLabel = $renderLabel( "rules_engine_condition", arguments.targetId );
			arguments.logger.info( $translateResource(
				  uri = "cms:datamanager.managefilters.segmentation.clone.log.start"
				, data = [ sourceLabel, targetLabel ]
			) );
		}

		var sourceChildren = dao.selectData(
			  filter = { parent_segmentation_filter=arguments.sourceId }
		);
		for( var child in sourceChildren ) {
			var childId = child.id;

			if ( canInfo ) {
				arguments.logger.info( $translateResource(
					  uri = "cms:datamanager.managefilters.segmentation.clone.log.copy.record"
					, data = [ $renderLabel( "rules_engine_condition", childId ) ]
				) );
			}

			StructDelete( child, "datecreated" );
			StructDelete( child, "datemodified" );
			StructDelete( child, "id" );
			child.parent_segmentation_filter = arguments.targetId;

			var newChildId = dao.insertData( child );

			cloneFilterChildren( argumentCollection=arguments, sourceId=childId, targetId=newChildId );
		}

		if ( canInfo ) {
			arguments.logger.info( $translateResource(
				  uri = "cms:datamanager.managefilters.segmentation.clone.log.finish"
				, data = [ sourceLabel, targetLabel ]
			) );
		}

		return true;
	}

	public struct function prepareAutoFormulaFilter(
		  required string objectName
		, required string propertyName
		, required string filter
		, required struct filterParams
	) {
		var suffix        = CreateUUId().lCase().replace( "-", "", "all" )
		var subQueryAlias = "formulaFieldSubquery" & suffix;
		var idField       = $getPresideObjectService().getIdField( arguments.objectName );
		var subquery      = $getPresideObjectService().selectData(
			  objectName          = arguments.objectName
			, selectFields        = [ idField, arguments.propertyName ]
			, having              = arguments.filter
			, filterParams        = arguments.filterParams
			, autoGroupBy         = true
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);
		var existsSubQuery = "select 1 from (#subQuery.sql#) #subQueryAlias# where #subqueryAlias#.#idField# = #arguments.objectName#.#idField#";

		return {
			  filter       = "exists (#$obfuscateSqlForPreside( existsSubQuery )#)"
			, filterParams = subquery.params
		};
	}

// PRIVATE HELPERS
	private struct function _getFilterPermissionFilter() {
		var adminUserId = $getAdminLoggedInUserId();
		var userGroups  = $getAdminPermissionService().listUserGroups( adminUserId );

		var params = {
			  owner            = adminUserId
			, "user_groups.id" = userGroups
		};
		var filter = "   ( filter_sharing_scope is null or filter_sharing_scope = 'global' )
		              or ( filter_sharing_scope = 'individual' and owner = :owner )
		              or ( filter_sharing_scope = 'group' and user_groups.id in (:user_groups.id) )";

		return { filter=filter, filterParams=params };
	}

	private numeric function _flattenSegmentationFilterToHoldingTable( holdingId, filter ) {
		var objectName      = arguments.filter.filter_object;
		var filterId        = arguments.filter.id;
		var idField         = $getPresideObjectService().getIdField( objectName );
		var bypassTenants   = [];
		var preparedFilters = [ prepareFilter(
			  objectName         = objectName
			, filterId           = filterId
			, ignoreSegmentation = true
		) ];

		if ( Len( arguments.filter.parent_segmentation_filter ) ) {
			ArrayPrepend( preparedFilters, prepareFilter(
				  objectName = objectName
				, filterId   = arguments.filter.parent_segmentation_filter
			) );
		}

		var objectTenant = _getTenancyService().getObjectTenant( objectName=objectName );
		if ( Len( Trim( objectTenant ) ) ) {
			bypassTenants = ListToArray( objectTenant );
		}

		return $getPresideObjectService().insertDataFromSelect(
			  objectName     = "rules_engine_filter_holding_data"
			, fieldList      = [ "filter", "object_name", "record_id", "holding_id" ]
			, selectDataArgs = {
				  objectName    = objectName
				, selectFields  = [ "'#filterId#'", "'#objectName#'", "#objectName#.#idField#", "'#arguments.holdingId#'" ]
				, extraFilters  = preparedFilters
				, bypassTenants = bypassTenants
			}
		);
	}

	private void function _clearHoldingTable( required string holdingId ) {
		$getPresideObject( "rules_engine_filter_holding_data" ).deleteData( filter={ holding_id=arguments.holdingId } );
	}

	private void function _addNewlyApplicableSegmentationRecords( holdingId, filterId, objectName ) {
		var outerJoinFilter   = $helpers.obfuscateSqlForPreside( "rules_engine_filter_data.record_id = rules_engine_filter_holding_data.record_id" );
		var notExistsSubquery = $getPresideObjectService().selectData(
			  objectName          = "rules_engine_filter_data"
			, selectFields        = [ "1" ]
			, filter              = { object_name=arguments.objectName, filter=arguments.filterId }
			, extraFilters        = [ { filter=outerJoinFilter } ]
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		$getPresideObjectService().insertDataFromSelect(
			  objectName     = "rules_engine_filter_data"
			, fieldList      = [ "filter", "object_name", "record_id" ]
			, selectDataArgs = {
				  objectName   = "rules_engine_filter_holding_data"
				, selectFields = [ "filter", "object_name", "record_id" ]
				, extraFilters = [ { filter={ holding_id=arguments.holdingId } } ]
				, filter       = "not exists (#$helpers.obfuscateSqlForPreside( notExistsSubquery.sql )#)"
				, filterParams = notExistsSubquery.params
			}
		);
	}

	private void function _removeNoLongerApplicableSegmentationRecords( holdingId, filterId, objectName ) {
		var outerJoinFilter = $helpers.obfuscateSqlForPreside( "rules_engine_filter_data.record_id = rules_engine_filter_holding_data.record_id" );
		var notExistsSubquery = $getPresideObjectService().selectData(
			  objectName          = "rules_engine_filter_holding_data"
			, selectFields        = [ "1" ]
			, filter              = { holding_id=arguments.holdingId, filter=arguments.filterId, object_name=arguments.objectName }
			, extraFilters        = [ { filter=outerJoinFilter } ]
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);
		var filterParams = {
			  object_name = arguments.objectName
			, filter      = arguments.filterId
		};

		StructAppend( filterParams, notExistsSubquery.params );

		$getPresideObject( "rules_engine_filter_data" ).deleteData(
			  filter       = "object_name = :object_name and filter = :filter and not exists ( #$helpers.obfuscateSqlForPreside( notExistsSubquery.sql )# )"
			, filterParams = filterParams
		);
	}

	private any function _calculateNextSegmentationCalculation( filter ) {
		var relativeToNow = Now();

		if ( !Len( filter.segmentation_frequency_unit ?: "" ) || !Val( filter.segmentation_frequency_measure ?: "" ) ) {
			return "";
		}

		var unit = $translateResource(
			  uri          = "enum.segmentationFilterTimeUnit:#filter.segmentation_frequency_unit#.cfmeasure"
			, defaultValue = "d"
		);

		return DateAdd( unit, filter.segmentation_frequency_measure, Now() );
	}

// GETTERS AND SETTERS
	private any function _getExpressionService() {
		return _expressionService;
	}
	private void function _setExpressionService( required any expressionService ) {
		_expressionService = arguments.expressionService;
	}

	private any function _getTenancyService() {
		return _tenancyService;
	}
	private void function _setTenancyService( required any tenancyService ) {
		_tenancyService = arguments.tenancyService;
	}
}