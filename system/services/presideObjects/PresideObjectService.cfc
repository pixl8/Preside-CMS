/**
 * The Preside Object Service is the main entry point API for interacting with **Preside Data Objects**. It provides CRUD operations for individual objects as well as many other useful utilities.
 * \n
 * For a full developer guide on using Preside Objects and this service, see [[presidedataobjects]].
 *
 * @presideservice
 * @singleton
 * @autodoc
 */
component displayName="Preside Object Service" {

// CONSTRUCTOR
	/**
	 * @objectDirectories.inject      presidecms:directories:preside-objects
	 * @objectReader.inject           PresideObjectReader
	 * @sqlSchemaSynchronizer.inject  SqlSchemaSynchronizer
	 * @adapterFactory.inject         AdapterFactory
	 * @sqlRunner.inject              SqlRunner
	 * @relationshipGuidance.inject   RelationshipGuidance
	 * @presideObjectDecorator.inject PresideObjectDecorator
	 * @versioningService.inject      VersioningService
	 * @labelRendererService.inject   LabelRendererService
	 * @filterService.inject          presideObjectSavedFilterService
	 * @selectDataViewService.inject  presideObjectSelectDataViewService
	 * @defaultQueryCache.inject      cachebox:DefaultQueryCache
	 * @interceptorService.inject     coldbox:InterceptorService
	 * @reloadDb.inject               coldbox:setting:syncDb
	 * @throwOnLongTableName.inject   coldbox:setting:throwOnLongTableName
	 */
	public any function init(
		  required array   objectDirectories
		, required any     objectReader
		, required any     sqlSchemaSynchronizer
		, required any     adapterFactory
		, required any     sqlRunner
		, required any     relationshipGuidance
		, required any     presideObjectDecorator
		, required any     versioningService
		, required any     labelRendererService
		, required any     filterService
		, required any     selectDataViewService
		, required any     defaultQueryCache
		, required any     interceptorService
		,          boolean reloadDb = true
		,          boolean throwOnLongTableName = false
	) {
		_setObjectDirectories( arguments.objectDirectories );
		_setObjectReader( arguments.objectReader );
		_setSqlSchemaSynchronizer( arguments.sqlSchemaSynchronizer );
		_setAdapterFactory( arguments.adapterFactory );
		_setSqlRunner( arguments.sqlRunner );
		_setRelationshipGuidance( arguments.relationshipGuidance );
		_setPresideObjectDecorator( arguments.presideObjectDecorator );
		_setFilterService( arguments.filterService );
		_setSelectDataViewService( arguments.selectDataViewService );
		_setDefaultQueryCache( arguments.defaultQueryCache );
		_setVersioningService( arguments.versioningService );
		_setLabelRendererService( arguments.labelRendererService );
		_setInterceptorService( arguments.interceptorService );
		_setThrowOnLongTableName( arguments.throwOnLongTableName );
		_setInstanceId( CreateObject('java','java.lang.System').identityHashCode( this ) );

		_loadObjects();

		if ( arguments.reloadDb ) {
			dbSync();
		}

		_setSimpleLocalCache({});
		_setCacheMap({});

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns an 'auto service' object instance of the given Preside Object.
	 * \n
	 * ${arguments}
	 * \n
	 * ## Example
	 *
	 * ```luceescript
	 * eventObject = presideObjectService.getObject( "event" );
	 * eventId     = eventObject.insertData( data={ title="Christmas", startDate="2014-12-25", endDate="2015-01-06" } );
	 * \n
	 * event       = eventObject.selectData( id=eventId )
	 *```
	 *
	 * @objectName.hint The name of the object to get
	 */
	public any function getObject( required string objectName ) autodoc=true {
		var obj = _getObject( arguments.objectName );

		if ( not StructKeyExists( obj, "decoratedInstance" ) ) {
			obj.decoratedInstance = _getPresideObjectDecorator().decorate(
				  objectName           = arguments.objectName
				, dsn                  = obj.meta.dsn
				, tableName            = obj.meta.tableName
				, objectInstance       = obj.instance
				, presideObjectService = this
			);
		}

		return obj.decoratedInstance;
	}

	/**
	 * Selects database records for the given object based on a variety of input parameters
	 * \n
	 * ${arguments}
	 * \n
	 * ## Examples
	 * \n
	 * ```luceescript
	 * // select a record by ID
	 * event = presideObjectService.selectData( objectName="event", id=rc.id );
	 * \n
	 * // select records using a simple filter.
	 * // notice the 'category.label as categoryName' field - this will
	 * // be automatically selected from the related 'category' object
	 * events = presideObjectService.selectData(
	 * \t      objectName   = "event"
	 * \t    , filter       = { category = rc.category }
	 * \t    , selectFields = [ "event.name", "category.label as categoryName", "event.category" ]
	 * \t    , orderby      = "event.name"
	 * );
	 * \n
	 * // select records with a plain SQL filter with added SQL params
	 * events = presideObjectService.selectData(
	 * \t      objectName   = "event"
	 * \t    , filter       = "category.label like :category.label"
	 * \t    , filterParams = { "category.label" = "%#rc.search#%" }
	 * );
	 * ```
	 *
	 * @objectName.hint              Name of the object from which to select data
	 * @id.hint                      ID of a record to select
	 * @selectFields.hint            Array of field names to select. Can include relationships, e.g. ['tags.label as tag']
	 * @extraSelectFields.hint       Array of field names to select in addition to `selectFields`. Can include relationships, e.g. ['tags.label as tag']. Use this if you want specific extra fields (e.g. formula fields) in addition to selecting all physical fields
	 * @includeAllFormulaFields.hint If true, all formula fields for the object will be added into the query
	 * @filter.hint                  Filter the records returned, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`
	 * @filterParams.hint            Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`
	 * @extraFilters.hint            An array of extra sets of filters. Each array should contain a structure with :code:`filter` and optional `code:`filterParams` keys.
	 * @orderBy.hint                 Plain SQL order by string
	 * @groupBy.hint                 Plain SQL group by string
	 * @autoGroupBy.hint             Whether or not to try to automatically calculate group by fields for the query
	 * @having.hint                  Plain SQL HAVING clause, can contain params that should be present in `filterParams` argument
	 * @maxRows.hint                 Maximum number of rows to select
	 * @startRow.hint                Offset the recordset when using maxRows
	 * @useCache.hint                Whether or not to automatically cache the result internally
	 * @fromVersionTable.hint        Whether or not to select the data from the version history table for the object
	 * @specificVersion.hint         Can be used to select a specific version when selecting from the version table
	 * @allowDraftVersions.hint      Choose whether or not to allow selecting from draft records and/or versions
	 * @forceJoins.hint              Can be set to "inner" / "left" to force *all* joins in the query to a particular join type
	 * @extraJoins.hint              An array of explicit joins to add to the query (can define subquery joins this way)
	 * @recordCountOnly.hint         If set to true, the method will just return the number of records that the select statement would return
	 * @getSqlAndParamsOnly.hint     If set to true, the method will not execute any query. Instead it will just return a struct with a `sql` key containing the plain string SQL that would have been executed and a `params` key with an array of params that would be included
	 * @formatSqlParams.hint         If set to true, params returned by `getSqlAndParamsOnly` will be in the format required by `selectData()`'s `filterParams`
	 * @distinct.hint                Whether or not the record set should be a 'distinct' select
	 * @tenantIds.hint               Struct of tenant IDs. Keys of the struct indicate the tenant, values indicate the ID. e.g. `{ site=specificSiteId }`. These values will override the current active tenant for the request.
	 * @bypassTenants.hint           Array of tenants to bypass. e.g. [ "site" ] to bypass site tenancy. See [[data-tenancy]] for more information on tenancy.
	 * @selectFields.docdefault      []
	 * @filter.docdefault            {}
	 * @filterParams.docdefault      {}
	 * @extraFilters.docdefault      []
	 * @extraJoins.docdefault        []
	 * @tenantIds.docdefault         {}
	 * @bypassTenants.docdefault     []
	 */
	public any function selectData(
		  required string  objectName
		,          string  id
		,          array   selectFields            = []
		,          array   extraselectFields       = []
		,          boolean includeAllFormulaFields = false
		,          any     filter                  = {}
		,          struct  filterParams            = {}
		,          array   extraFilters            = []
		,          array   savedFilters            = []
		,          string  orderBy                 = ""
		,          string  groupBy                 = ""
		,          boolean autoGroupBy             = false
		,          string  having                  = ""
		,          numeric maxRows                 = 0
		,          numeric startRow                = 1
		,          boolean useCache                = _getUseCacheDefault( arguments.objectName )
		,          boolean fromVersionTable        = false
		,          numeric specificVersion         = 0
		,          boolean allowDraftVersions      = _getDefaultAllowDraftVersions()
		,          string  forceJoins              = ""
		,          array   extraJoins              = []
		,          boolean recordCountOnly         = false
		,          boolean getSqlAndParamsOnly     = false
		,          boolean formatSqlParams         = false
		,          boolean distinct                = false
		,          struct  tenantIds               = {}
		,          array   bypassTenants           = []
		,          array   ignoreDefaultFilters    = []
	) autodoc=true {
		var args = _addDefaultFilters( _cleanupPropertyAliases( argumentCollection=Duplicate( arguments ) ) );
		var interceptorResult = _announceInterception( "preSelectObjectData", args );
		if ( IsBoolean( interceptorResult.abort ?: "" ) && interceptorResult.abort ) {
			return IsQuery( interceptorResult.returnValue ?: "" ) ? interceptorResult.returnValue : QueryNew('');
		}

		if ( !args.allowDraftVersions && !args.fromVersionTable && objectIsVersioned( args.objectName ) ) {
			args.extraFilters.append( _getDraftExclusionFilter( args.objectname ) );
			if ( ( arguments.selectManyToMany ?: false ) && !isEmpty( arguments.relationshipTable ?: "" ) && objectIsVersioned( arguments.relationshipTable ) ) {
				args.extraFilters.append( _getDraftExclusionFilter( arguments.relationshipTable ) );
			}
		}

		args.extraFilters.append( _expandSavedFilters( argumentCollection=args ), true );

		if ( args.useCache ) {
			args.cachekey = _getCacheKey( argumentCollection=args );

			_announceInterception( "onCreateSelectDataCacheKey", args );

			var cachedResult = _getDefaultQueryCache( args.objectName ).get( args.cacheKey );
			if ( !IsNull( local.cachedResult ) ) {
				return cachedResult;
			}
		}

		var objMeta = _getObject( args.objectName ).meta;
		var adapter = _getAdapter( objMeta.dsn );

		args.selectFields   = parseSelectFields( argumentCollection=args );
		args.preparedFilter = _prepareFilter(
			  argumentCollection = args
			, adapter            = adapter
			, columnDefinitions  = objMeta.properties
		);

		args.adapter     = adapter;
		args.objMeta     = objMeta;
		args.orderBy     = arguments.recordCountOnly ? "" : _parseOrderBy( args.orderBy, args.objectName, args.adapter );
		args.groupBy     = _autoPrefixBareProperty( args.objectName, args.groupBy, args.adapter );
		if ( !Len( Trim( args.groupBy ) ) && args.autoGroupBy ) {
			args.groupBy = _autoCalculateGroupBy( args.selectFields );
		}

		args.joinTargets = _extractForeignObjectsFromArguments( argumentCollection=args );
		args.joins       = _getJoinsFromJoinTargets( argumentCollection=args );

		if ( args.fromVersionTable && objectIsVersioned( args.objectName ) ) {
			args.result = _selectFromVersionTables(
				  argumentCollection = args
				, filter             = args.preparedFilter.filter
				, params             = args.preparedFilter.params
				, originalTableName  = args.objMeta.tableName
				, distinct           = args.distinct
			);
		} else {
			var sql = args.adapter.getSelectSql(
				  argumentCollection = args
				, tableName          = args.objMeta.tableName
				, tableAlias         = args.objectName
				, selectColumns      = args.selectFields
				, filter             = args.preparedFilter.filter
				, having             = args.preparedFilter.having
				, joins              = _convertObjectJoinsToTableJoins( argumentCollection=args )
				, distinct           = args.distinct
			);

			if ( arguments.recordCountOnly ) {
				sql = args.adapter.getCountSql( sql );
			}
			if ( arguments.getSqlAndParamsOnly ) {
				return {
					  sql    = sql
					, params = arguments.formatSqlParams ? _formatParams( args.preparedFilter.params ) : args.preparedFilter.params
				};
			}
			args.result = _runSql( sql=sql, dsn=args.objMeta.dsn, params=args.preparedFilter.params );
			if ( arguments.recordCountOnly ) {
				args.result = Val( args.result.record_count ?: "" );
			}
		}

		if ( args.useCache ) {
			_getDefaultQueryCache( args.objectName ).set( args.cacheKey, args.result );
		}

		_announceInterception( "postSelectObjectData", args );

		return args.result;
	}

	/**
	 * Selects data from a preside select data view (see [[select-data-views|Select Data Views]]).
	 * Any additional arguments will be appended or merged with the views selectData
	 * arguments and sent through to the selectData call
	 *
	 * @autodoc   true
	 * @view.hint Name of the view to select data from
	 */
	public any function selectView( required string view ) {
		return selectData( argumentCollection=_getSelectDataArgsFromView( argumentCollection=arguments ) );
	}

	private function _formatParams( required array rawParams ) {
		var formattedParams = {};
		for( var param in arguments.rawParams ) {
			formattedParams[ param.name ] = { value=param.value, type=param.type };
			if ( param.keyExists( "list" ) ) {
				formattedParams[ param.name ].list = param.list;
			}
			if ( param.keyExists( "separator" ) ) {
				formattedParams[ param.name ].separator = param.separator;
			}
		}
		return formattedParams;
	}

	/**
	 * Inserts a record into the database, returning the ID of the newly created record
	 * \n
	 * ${arguments}
	 * \n
	 * Example:
	 * \n
	 * ```luceescript
	 * newId = presideObjectService.insertData(
	 * \t      objectName = "event"
	 * \t    , data       = { name="Summer BBQ", startdate="2015-08-23", enddate="2015-08-23" }
	 * );
	 * ```
	 *
	 * @autodoc                      true
	 * @objectName.hint              Name of the object in which to to insert a record
	 * @data.hint                    Structure of data whose keys map to the properties that are defined on the object
	 * @insertManyToManyRecords.hint Whether or not to insert multiple relationship records for properties that have a many-to-many relationship
	 * @isDraft.hint                 Whether or not to save the record as a draft record
	 * @useVersioning.hint           Whether or not to use the versioning system with the insert. If the object is setup to use versioning (default), this will default to true.
	 * @versionNumber.hint           If using versioning, specify a version number to save against (if none specified, one will be created automatically)
	 * @bypassTenants.hint           Array of tenants to ignore (i.e. when the insert data wants to create a record in an alternative tenant to the current one)
	 * @clearCaches.hint             Whether or not to clear caches related to the object whose record you are creating
	 * @useVersioning.docdefault     automatic
	 * @clearCaches.docdefault       Defaults to whether query caching is enabled or not for this object
	 */
	public any function insertData(
		  required string  objectName
		, required struct  data
		,          boolean insertManyToManyRecords = false
		,          boolean isDraft                 = false
		,          boolean useVersioning           = objectIsVersioned( arguments.objectName )
		,          numeric versionNumber           = 0
		,          array   bypassTenants           = []
		,          boolean clearCaches             = _objectUsesCaching( arguments.objectName )

	) autodoc=true {
		var interceptorResult = _announceInterception( "preInsertObjectData", arguments );

		if ( IsBoolean( interceptorResult.abort ?: "" ) && interceptorResult.abort ) {
			return interceptorResult.returnValue ?: "";
		}

		var args               = _cleanupPropertyAliases( argumentCollection=Duplicate( arguments ) );
		var obj                = _getObject( args.objectName ).meta;
		var adapter            = _getAdapter( obj.dsn );
		var dateCreatedField   = getDateCreatedField( args.objectName );
		var dateModifiedField  = getDateModifiedField( args.objectName );
		var idField            = getIdField( args.objectName );
		var sql                = "";
		var key                = "";
		var params             = "";
		var result             = "";
		var newId              = "";
		var rightNow           = DateFormat( Now(), "yyyy-mm-dd" ) & " " & TimeFormat( Now(), "HH:mm:ss" );
		var cleanedData        = _addDefaultValuesToDataSet( args.objectName, args.data );
		var manyToManyData     = {};
		var requiresVersioning = args.useVersioning && objectIsVersioned( args.objectName ) && versioningRequiredOnInsert( args.objectName );
		var versionNumber      = 0;

		cleanedData.append( _addGeneratedValues(
			  operation  = "insert"
			, objectName = arguments.objectName
			, data       = cleanedData
		) );
		for( key in cleanedData ){
			if ( args.insertManyToManyRecords and getObjectPropertyAttribute( objectName, key, "relationship", "none" ).reFindNoCase( "(many|one)\-to\-many" ) ) {
				manyToManyData[ key ] = cleanedData[ key ];
			}
			if ( not ListFindNoCase( obj.dbFieldList, key ) ) {
				StructDelete( cleanedData, key );
			}
		}

		if ( dateCreatedField.len() && StructKeyExists( obj.properties, dateCreatedField ) && !StructKeyExists( cleanedData, dateCreatedField ) ) {
			cleanedData[ dateCreatedField ] = rightNow;
		}
		if ( dateModifiedField.len() && StructKeyExists( obj.properties, dateModifiedField ) && !StructKeyExists( cleanedData, dateModifiedField ) ) {
			cleanedData[ dateModifiedField ] = rightNow;
		}
		if ( ListFindNoCase( obj.dbFieldList, idField ) && StructKeyExists( obj.properties, idField ) ) {
			if ( not StructKeyExists( cleanedData, idField ) or not Len( Trim( cleanedData[idField] ) ) ) {
				newId = _generateNewIdWhenNecessary( generator=( obj.properties[idField].generator ?: "UUID" ) );
				if ( Len( Trim( newId ) ) ) {
					cleanedData[idField]= newId;
				}
			}else{
				newId = cleanedData[idField];
			}
		}
		if ( objectIsVersioned( args.objectName ) ) {
			cleanedData._version_is_draft = cleanedData._version_has_drafts = args.isDraft;
		}

		transaction {
			if ( requiresVersioning ) {
				versionNumber = _getVersioningService().saveVersionForInsert(
					  objectName     = args.objectName
					, data           = cleanedData
					, manyToManyData = manyToManyData
					, versionNumber  = args.versionNumber ? args.versionNumber : getNextVersionNumber()
					, isDraft        = args.isDraft
				);
			}

			sql    = adapter.getInsertSql( tableName = obj.tableName, insertColumns = StructKeyArray( cleanedData ) );
			params = _convertDataToQueryParams(
				  objectName        = args.objectName
				, columnDefinitions = obj.properties
				, data              = cleanedData
				, dbAdapter         = adapter
			);

			result = _runSql( sql=sql[1], dsn=obj.dsn, params=params, returnType=adapter.getInsertReturnType() );

			if ( adapter.requiresManualCommitForTransactions() ){
				_runSql( sql='commit', dsn=obj.dsn );
			}

			newId = Len( Trim( newId ) ) ? newId : ( adapter.getGeneratedKey(result) ?: "" );
			if ( Len( Trim( newId ) ) ) {
				for( key in manyToManyData ){
					var relationship = getObjectPropertyAttribute( objectName, key, "relationship", "none" );

					if ( relationship == "many-to-many" ) {
						syncManyToManyData(
							  sourceObject        = args.objectName
							, sourceProperty      = key
							, sourceId            = newId
							, targetIdList        = manyToManyData[ key ]
							, requiresVersionSync = false
							, isDraft             = args.isDraft
						);
					} else if ( relationship == "one-to-many" ) {
						var isOneToManyConfigurator = isOneToManyConfiguratorObject( args.objectName, key );

						if ( isOneToManyConfigurator ) {
							syncOneToManyConfiguratorData(
								  sourceObject     = args.objectName
								, sourceProperty   = key
								, sourceId         = newId
								, configuratorData = manyToManyData[ key ]
								, versionNumber    = versionNumber
							);
						} else {
							syncOneToManyData(
								  sourceObject   = args.objectName
								, sourceProperty = key
								, sourceId       = newId
								, targetIdList   = manyToManyData[ key ]
							);
						}
					}
				}
			}
		}

		if ( arguments.clearCaches ) {
			clearRelatedCaches(
				  objectName              = args.objectName
				, filter                  = ""
				, filterParams            = {}
				, clearSingleRecordCaches = false
			);
		}

		var interceptionArgs       = args;
		    interceptionArgs.newId = newId;
		    interceptionArgs.result = result;

		_announceInterception( "postInsertObjectData", interceptionArgs );

		return newId;
	}


	/**
	 * Inserts records into a database based on a selectData() set of arguments and provided
	 * fieldlist.
	 *
	 * @autodoc                true
	 * @objectName.hint        Name of the object in which to to insert records
	 * @selectDataArgs.hint    Struct of arguments that are valid to pass to the [[presideobjectservice-selectdata]] method
	 * @fieldList.hint         Array of table field names that the select fields in the select statement should map to for the insert
	 * @clearCaches.hint       Whether or not to clear caches related to the object whose record you are creating
	 * @clearCaches.docdefault Defaults to whether query caching is enabled or not for this object
	 */
	public numeric function insertDataFromSelect(
		  required string  objectName
		, required struct  selectDataArgs
		, required array   fieldList
		,          boolean clearCaches = _objectUsesCaching( arguments.objectName )
	) {
		var obj       = _getObject( arguments.objectName ).meta;
		var adapter   = _getAdapter( obj.dsn );
		var selectSql = selectData( argumentCollection=arguments.selectDataArgs, getSqlAndParamsOnly=true );
		var insertSql = adapter.getInsertSql(
			  tableName     = obj.tableName
			, insertColumns = arguments.fieldList
			, selectStatement = selectSql.sql
		);

		var result = _runSql(
			  sql        = insertSql[ 1 ]
			, dsn        = obj.dsn
			, params     = selectSql.params
			, returnType = "info"
		);

		if ( arguments.clearCaches ) {
			clearRelatedCaches(
				  objectName              = arguments.objectName
				, filter                  = ""
				, filterParams            = {}
				, clearSingleRecordCaches = false
			);
		}

		return Val( result.recordCount );
	}

	/**
	 * Updates records in the database with a new set of data. Returns the number of records affected by the operation.
	 * \n
	 * ${arguments}
	 * \n
	 * ## Examples
	 * \n
	 * ```luceescript
	 * // update a single record
	 * updated = presideObjectService.updateData(
	 * \t      objectName = "event"
	 * \t    , id         = eventId
	 * \t    , data       = { enddate = "2015-01-31" }
	 * );
	 * \n
	 * // update multiple records
	 * updated = presideObjectService.updateData(
	 * \t      objectName     = "event"
	 * \t    , data           = { cancelled = true }
	 * \t    , filter         = { category = rc.category }
	 * );
	 * \n
	 * // update all records
	 * updated = presideObjectService.updateData(
	 * \t      objectName     = "event"
	 * \t    , data           = { cancelled = true }
	 * \t    , forceUpdateAll = true
	 * );
	 * ```
	 *
	 * @objectName.hint              Name of the object whose records you want to update
	 * @data.hint                    Structure of data containing new values. Keys should map to properties on the object.
	 * @id.hint                      ID of a single record to update
	 * @filter.hint                  Filter for which records are updated, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`
	 * @filterParams.hint            Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`
	 * @extraFilters.hint            An array of extra sets of filters. Each array should contain a structure with :code:`filter` and optional `code:`filterParams` keys.
	 * @forceUpdateAll.hint          If no ID and no filters are supplied, this must be set to **true** in order for the update to process
	 * @updateManyToManyRecords.hint Whether or not to update multiple relationship records for properties that have a many-to-many relationship
	 * @isDraft.hint                 Whether or not the record update is a draft change. Draft changes are only saved against the version table until published.
	 * @useVersioning.hint           Whether or not to use the versioning system with the update. If the object is setup to use versioning (default), this will default to true.
	 * @versionNumber.hint           If using versioning, specify a version number to save against (if none specified, one will be created automatically)
	 * @setDateModified.hint         If true (default), updateData will automatically set the datelastmodified date on your record to the current date/time
	 * @clearCaches.hint             Whether or not to clear caches related to the object whose record you are updating
	 * @useVersioning.docdefault     auto
	 * @clearCaches.docdefault       Defaults to whether query caching is enabled or not for this object
	 */
	public numeric function updateData(
		  required string  objectName
		, required struct  data
		,          string  id
		,          any     filter                  = {}
		,          struct  filterParams            = {}
		,          array   extraFilters            = []
		,          array   savedFilters            = []
		,          boolean forceUpdateAll          = false
		,          boolean updateManyToManyRecords = false
		,          boolean isDraft                 = false
		,          boolean useVersioning           = objectIsVersioned( arguments.objectName )
		,          numeric versionNumber           = 0
		,          boolean forceVersionCreation    = false
		,          boolean setDateModified         = true
		,          boolean clearCaches             = _objectUsesCaching( arguments.objectName )
		,          boolean calculateChangedData    = false
	) autodoc=true {
		var interceptorResult = _announceInterception( "preUpdateObjectData", arguments );

		if ( IsBoolean( interceptorResult.abort ?: "" ) && interceptorResult.abort ) {
			return Val( interceptorResult.returnValue ?: 0 );
		}

		var obj                = _getObject( arguments.objectName ).meta;
		var adapter            = _getAdapter( obj.dsn );
		var sql                = "";
		var result             = "";
		var joinTargets        = "";
		var joins              = [];
		var cleanedData        = Duplicate( arguments.data );
		var manyToManyData     = {}
		var key                = "";
		var requiresVersioning = arguments.useVersioning && objectIsVersioned( arguments.objectName );
		var versionNumber      = 0;
		var preparedFilter     = "";
		var idField            = getIdField( arguments.objectName );
		var dateModifiedField  = getDateModifiedField( arguments.objectName );

		for( key in cleanedData ){
			if ( arguments.updateManyToManyRecords and getObjectPropertyAttribute( objectName, key, "relationship", "none" ).reFindNoCase( "(one|many)\-to\-many" ) ) {
				manyToManyData[ key ] = cleanedData[ key ];
				cleanedData.delete( key );
			} else if ( !ListFindNoCase( obj.dbFieldList, key ) ) {
				cleanedData.delete( key );
			}
		}
		cleanedData.append( _addGeneratedValues(
			  operation  = "update"
			, objectName = arguments.objectName
			, data       = cleanedData
			, id         = arguments.id
		) );

		if ( !Len( Trim( arguments.id ?: "" ) ) and _isEmptyFilter( arguments.filter ) and not arguments.forceUpdateAll ) {
			throw(
				  type    = "PresideObjects.updateAllProtection"
				, message = "A call to update records in [#arguments.objectName#] was made without any filter which would lead to all records being updated"
				, detail  = "If you wish to update all records, you must set the [forceUpdateAll] argument of the [updateData] method to true"
			);
		}

		if ( arguments.setDateModified && StructKeyExists( obj.properties, dateModifiedField ) and not StructKeyExists( cleanedData, dateModifiedField ) ) {
			cleanedData[ dateModifiedField ] = DateFormat( Now(), "yyyy-mm-dd" ) & " " & TimeFormat( Now(), "HH:mm:ss" );
		}
		preparedFilter = _prepareFilter(
			  adapter            = adapter
			, columnDefinitions  = obj.properties
			, argumentCollection = arguments
		);

		joinTargets = _extractForeignObjectsFromArguments( argumentCollection=arguments, data=cleanedData, preparedFilter=preparedFilter );
		if ( ArrayLen( joinTargets ) ) {
			joins = _getRelationshipGuidance().calculateJoins( objectName = arguments.objectName, joinTargets = joinTargets );
			joins = _convertObjectJoinsToTableJoins( joins = joins, argumentCollection = arguments );
		}

		if ( requiresVersioning || arguments.calculateChangedData ) {
			arguments.oldData = selectData(
				  argumentCollection = arguments
				, allowDraftVersions = true
				, fromVersionTable   = arguments.isDraft
			);
			if ( !arguments.oldData.recordCount && arguments.isDraft ) {
				arguments.oldData = selectData(
					  argumentCollection = arguments
					, allowDraftVersions = true
					, fromVersionTable   = false
				);
			}

			arguments.changedData = {};
			for( var record in arguments.oldData ) {

				var versionedManyToManyFields = _getVersioningService().getVersionedManyToManyFieldsForObject( arguments.objectName );
				var oldManyToManyData = versionedManyToManyFields.len() ? getDeNormalizedManyToManyData(
					objectName         = arguments.objectName
					, id               = record[ idField ]
					, selectFields     = versionedManyToManyFields
				) : {};

				var newDataForChangedFieldsCheck = Duplicate( cleanedData );
				newDataForChangedFieldsCheck.append( manyToManyData );
				var changedFields =  _getVersioningService().getChangedFields(
					  objectName             = arguments.objectName
					, recordId               = record[ idField ]
					, newData                = newDataForChangedFieldsCheck
					, existingData           = record
					, existingManyToManyData = oldManyToManyData
				);
				if ( ArrayLen( changedFields ) ) {
					arguments.changedData[ record[ idField ] ] = {};
				}
				for( var field in changedFields ) {
					arguments.changedData[ record[ idField ] ][ field ] = cleanedData[ field ] ?: "";
				}
			}
		}

		transaction {
			if ( requiresVersioning ) {
				versionNumber = _getVersioningService().saveVersionForUpdate(
					  argumentCollection   = arguments
					, filter               = preparedFilter.filter
					, filterParams         = preparedFilter.filterParams
					, data                 = cleanedData
					, manyToManyData       = manyToManyData
					, existingRecords      = arguments.oldData
					, versionNumber        = arguments.versionNumber ? arguments.versionNumber : getNextVersionNumber()
				);
			} else if ( objectIsVersioned( arguments.objectName ) && Len( Trim( arguments.id ?: "" ) ) ) {
				_getVersioningService().updateLatestVersionWithNonVersionedChanges(
					  objectName = arguments.objectName
					, recordId   = arguments.id
					, data       = cleanedData
				);
			}

			if ( arguments.useVersioning ) {
				if ( arguments.isDraft ) {
					if ( !_isDraft( argumentCollection=arguments ) ) {
						cleanedData = { _version_has_drafts = true };
					}
				} else {
					cleanedData._version_is_draft   = false;
					cleanedData._version_has_drafts = false;
				}
			}

			preparedFilter.params = _arrayMerge( preparedFilter.params, _convertDataToQueryParams(
				  objectName        = arguments.objectName
				, columnDefinitions = obj.properties
				, data              = cleanedData
				, dbAdapter         = adapter
				, preFix            = "set__"
			) );

			sql = adapter.getUpdateSql(
				  tableName     = obj.tableName
				, tableAlias    = arguments.objectName
				, updateColumns = StructKeyArray( cleanedData )
				, filter        = preparedFilter.filter
				, joins         = joins
			);
			result = _runSql( sql=sql, dsn=obj.dsn, params=preparedFilter.params, returnType="info" );

			if ( StructCount( manyToManyData ) ) {
				var updatedRecords = [];

				if ( Len( Trim( arguments.id ?: "" ) ) ) {
					updatedRecords = [ arguments.id ];
				} else {
					updatedRecords = selectData(
						  objectName   = arguments.objectName
						, selectFields = [ "#adapter.escapeEntity( idField )# as id" ]
						, filter       = preparedFilter.filter
						, filterParams = preparedFilter.filterParams
					);
					updatedRecords = ListToArray( updatedRecords.id );
				}

				for( key in manyToManyData ){
					var relationship = getObjectPropertyAttribute( objectName, key, "relationship", "none" );

					if ( relationship == "many-to-many" ) {
						for( var updatedId in updatedRecords ) {
							syncManyToManyData(
								  sourceObject        = arguments.objectName
								, sourceProperty      = key
								, sourceId            = updatedId
								, targetIdList        = manyToManyData[ key ]
								, requiresVersionSync = false
								, isDraft             = arguments.isDraft
							);
						}
					} else if ( relationship == "one-to-many" ) {
						var isOneToManyConfigurator = isOneToManyConfiguratorObject( arguments.objectName, key );

						for( var updatedId in updatedRecords ) {
							if ( isOneToManyConfigurator ) {
								syncOneToManyConfiguratorData(
									  sourceObject     = arguments.objectName
									, sourceProperty   = key
									, sourceId         = updatedId
									, configuratorData = manyToManyData[ key ]
									, versionNumber    = versionNumber
								);
							} else {
								syncOneToManyData(
									  sourceObject   = arguments.objectName
									, sourceProperty = key
									, sourceId       = updatedId
									, targetIdList   = manyToManyData[ key ]
								);

							}
						}
					}
				}
			}
		}

		if ( arguments.clearCaches && Val( result.recordCount ?: 0 ) ) {
			clearRelatedCaches(
				  objectName   = arguments.objectName
				, filter       = preparedFilter.filter
				, filterParams = preparedFilter.filterParams
			);
		}

		var interceptionArgs        = arguments;
		    interceptionArgs.result = result;
		_announceInterception( "postUpdateObjectData", interceptionArgs );

		return Val( result.recordCount ?: 0 );
	}

	/**
	 * Deletes records from the database. Returns the number of records deleted.
	 * \n
	 * ${arguments}
	 * \n
	 * ## Examples
	 * \n
	 * ```luceescript
	 * // delete a single record
	 * deleted = presideObjectService.deleteData(
	 * \t      objectName = "event"
	 * \t    , id         = rc.id
	 * );
	 * \n
	 * // delete multiple records using a filter
	 * // (note we are filtering on a column in a related object, "category")
	 * deleted = presideObjectService.deleteData(
	 * \t      objectName   = "event"
	 * \t    , filter       = "category.label != :category.label"
	 * \t    , filterParams = { "category.label" = "BBQs" }
	 * );
	 * \n
	 * // delete all records
	 * // (note we are filtering on a column in a related object, "category")
	 * deleted = presideObjectService.deleteData(
	 * \t      objectName     = "event"
	 * \t    , forceDeleteAll = true
	 * );
	 * ```
	 *
	 * @objectName.hint        Name of the object from whose database table records are to be deleted
	 * @id.hint                ID of a record to delete
	 * @filter.hint            Filter for records to delete, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`
	 * @filterParams.hint      Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`
	 * @extraFilters.hint      An array of extra sets of filters. Each array should contain a structure with :code:`filter` and optional `code:`filterParams` keys.
	 * @forceDeleteAll.hint    If no id or filter supplied, this must be set to **true** in order for the delete to process
 	 * @clearCaches.hint       Whether or not to clear caches related to the object whose record you are deleting
	 * @clearCaches.docdefault Defaults to whether query caching is enabled or not for this object
	 */
	public numeric function deleteData(
		  required string  objectName
		,          string  id
		,          any     filter           = {}
		,          struct  filterParams     = {}
		,          array   extraFilters     = []
		,          array   savedFilters     = []
		,          boolean forceDeleteAll   = false
		,          string  forceJoins       = ""
		,          boolean fromVersionTable = false
		,          boolean clearCaches      = _objectUsesCaching( arguments.objectName )
	) autodoc=true {
		var interceptorResult = _announceInterception( "preDeleteObjectData", arguments );

		if ( IsBoolean( interceptorResult.abort ?: "" ) && interceptorResult.abort ) {
			return Val( interceptorResult.returnValue ?: 0 );
		}

		var args           = _cleanupPropertyAliases( argumentCollection=Duplicate( arguments ) );
		var obj            = _getObject( args.objectName ).meta;
		var adapter        = _getAdapter( obj.dsn );
		var sql            = "";
		var result         = "";
		var preparedFilter = "";

		if ( !Len( Trim( args.id ?: "" ) ) && _isEmptyFilter( args.filter ) && !args.forceDeleteAll ) {
			throw(
				  type    = "PresideObjects.deleteAllProtection"
				, message = "A call to delete records in [#args.objectName#] was made without any filter which would lead to all records being deleted"
				, detail  = "If you wish to delete all records, you must set the [forceDeleteAll] argument of the [deleteData] method to true"
			);
		}

		args.preparedFilter = _prepareFilter(
			  adapter           = adapter
			, columnDefinitions = obj.properties
			, argumentCollection = args
		);

		args.joinTargets = _extractForeignObjectsFromArguments( argumentCollection=args );
		args.joins       = _getJoinsFromJoinTargets( argumentCollection=args );

		sql = adapter.getDeleteSql(
			  tableName  = obj.tableName
			, tableAlias = args.objectName
			, filter     = args.preparedFilter.filter
			, joins      = _convertObjectJoinsToTableJoins( argumentCollection=args )
		);

		result = _runSql( sql=sql, dsn=obj.dsn, params=args.preparedFilter.params, returnType="info" );

		if ( arguments.clearCaches && Val( result.recordCount ?: 0 ) ) {
			clearRelatedCaches(
				  objectName   = args.objectName
				, filter       = args.preparedFilter.filter
				, filterParams = args.preparedFilter.filterParams
			);
		}

		var interceptionArgs        = args;
		    interceptionArgs.result = result;
		_announceInterception( "postDeleteObjectData", interceptionArgs );

		return Val( result.recordCount ?: 0 );
	}

	/**
	 * Returns true if records exist that match the supplied fillter, false otherwise.
	 * \n
	 * >>> In addition to the named arguments here, you can also supply any valid arguments
	 * that can be supplied to the [[presideobjectservice-selectdata]] method
	 * \n
	 * ${arguments}
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * eventsExist = presideObjectService.dataExists(
	 * \t  objectName = "event"
	 * \t, filter     = { category = rc.category }
	 * );
	 * ```
	 *
	 * @objectName.hint Name of the object in which the records may or may not exist
	 */
	public boolean function dataExists( required string  objectName ) autodoc=true {
		var args = arguments;
		args.useCache     = false;
		args.selectFields = [ "1" ];

		return selectData( argumentCollection=args ).recordCount;
	}

	/**
	 * Selects records from many-to-many relationships
	 * \n
	 * >>> You can pass additional arguments to those specified below and they will all be passed to the [[presideobjectservice-selectdata]] method
	 * \n
	 * ${arguments}
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * tags = presideObjectService.selectManyToManyData(
	 * \t      objectName   = "event"
	 * \t    , propertyName = "tags"
	 * \t    , orderby      = "tags.label"
	 * );
	 * ```
	 *
	 * @objectName.hint   Name of the object that has the many-to-many property defined
	 * @propertyName.hint Name of the many-to-many property
	 * @selectFields.hint Array of fields to select
	 * @orderBy.hint      Plain SQL order by statement
	 */
	public query function selectManyToManyData(
		  required string  objectName
		, required string  propertyName
		,          array   selectFields = []
		,          string  orderBy      = ""
	) autodoc=true {
		if ( !isManyToManyProperty( arguments.objectName, arguments.propertyName ) ) {
			throw(
				  type    = "PresideObjectService.notManyToMany"
				, message = "The property [#arguments.propertyName#] of object [#arguments.objectName#] is not a many-to-many field"
			);
		}

		var relatedTo      = getObjectPropertyAttribute( arguments.objectName, arguments.propertyName, "relatedTo", "" );
		var obj            = _getObject( relatedTo );
		var selectDataArgs = Duplicate( arguments );

		StructDelete( selectDataArgs, "propertyName" );
		selectDataArgs.forceJoins = "inner"; // many-to-many joins are not required so "left" by default. Here we absolutely want inner joins.

		if ( not ArrayLen( selectDataArgs.selectFields ) ) {
			var dbAdapter = getDbAdapterForObject( relatedTo );
			selectDataArgs.selectFields = ListToArray( obj.meta.dbFieldList );
			for( var i=1; i <= selectDataArgs.selectFields.len(); i++ ) {
				selectDataArgs.selectFields[i] = arguments.propertyName & "." & selectDataArgs.selectFields[i];
			}
		}

		if ( !Len( Trim( selectDataArgs.orderBy ) ) ) {
			var relatedVia   = getObjectPropertyAttribute( arguments.objectName, arguments.propertyName, "relatedVia", "" );
			var hasSortOrder = Len( Trim( relatedVia ) ) && StructKeyExists( getObjectProperties( relatedVia ), "sort_order" );
			if ( hasSortOrder ) {
				selectDataArgs.orderBy = relatedVia & ".sort_order";
			}
		}

		selectDataArgs.selectManyToMany  = true;
		selectDataArgs.relationshipTable = getObjectPropertyAttribute( arguments.objectName, arguments.propertyName, "relatedVia", "" );

		return selectData( argumentCollection = selectDataArgs );
	}

	/**
	 * Synchronizes a record's related object data for a given property. Returns true on success, false otherwise.
	 * \n
	 * ${arguments}
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * presideObjectService.syncManyToManyData(
	 * \t      sourceObject   = "event"
	 * \t    , sourceProperty = "tags"
	 * \t    , sourceId       = rc.eventId
	 * \t    , targetIdList   = rc.tags // e.g. "635,1,52,24"
	 * );
	 * ```
	 *
	 * @sourceObject.hint   The object that contains the many-to-many property
	 * @sourceProperty.hint The name of the property that is defined as a many-to-many relationship
	 * @sourceId.hint       ID of the record whose related data we are to synchronize
	 * @targetIdList.hint   Comma separated list of IDs of records representing records in the related object
	 */
	public boolean function syncManyToManyData(
		  required string  sourceObject
		, required string  sourceProperty
		, required string  sourceId
		, required string  targetIdList
		,          boolean requiresVersionSync = true
		,          boolean isDraft             = false
	) autodoc=true {
		if ( arguments.requiresVersionSync ) {
			return updateData(
				  objectName              = arguments.sourceObject
				, id                      = arguments.sourceId
				, data                    = { "#arguments.sourceProperty#" = arguments.targetIdList }
				, updateManyToManyRecords = true
			) > 0;
		}

		var prop = getObjectProperty( arguments.sourceObject, arguments.sourceProperty );
		var targetObject = prop.relatedTo ?: "";
		var pivotTable   = prop.relatedVia ?: "";
		var sourceFk     = prop.relationshipIsSource ? prop.relatedViaSourceFk : prop.relatedViaTargetFk;
		var targetFk     = prop.relationshipIsSource ? prop.relatedViaTargetFk : prop.relatedViaSourceFk;

		if ( Len( Trim( pivotTable ) ) and Len( Trim( targetObject ) ) ) {
			var newRecords      = ListToArray( arguments.targetIdList );
			var newAddedRecords = duplicate( newRecords );
			var existingRecords = [];
			var anythingChanged = false;
			var hasSortOrder    = StructKeyExists( getObjectProperties( pivotTable ), "sort_order" );
			var currentSelect   = [ "#targetFk# as targetId" ];

			if ( hasSortOrder ) {
				currentSelect.append( "sort_order" );
			}

			transaction {
				var currentRecords = selectData(
					  objectName   = pivotTable
					, selectFields = currentSelect
					, filter       = { "#sourceFk#" = arguments.sourceId }
					, useCache     = false
				);

				for( var record in currentRecords ) {
					if ( newRecords.find( record.targetId ) && ( !hasSortOrder || newRecords.find( record.targetId ) == record.sort_order ) ) {
						ArrayDelete( newAddedRecords, record.targetId );
						ArrayAppend( existingRecords, record.targetId );
					} else {
						anythingChanged = true;
						break;
					}
				}

				anythingChanged = anythingChanged || newAddedRecords.len();

				if ( anythingChanged && !arguments.isDraft ) {
					deleteData(
						  objectName = pivotTable
						, filter     = { "#sourceFk#" = arguments.sourceId }
					);


					for( var i=1; i <=newRecords.len(); i++ ) {
						insertData(
							  objectName    = pivotTable
							, useVersioning = false
							, data          = { "#sourceFk#"=arguments.sourceId, "#targetFk#"=newRecords[i], sort_order=i, _version_has_drafts=arguments.isDraft }
						);
					}
				}
			}
		}

		return true;
	}

	/**
	 * Synchronizes a record's related one-to-many object data for a given property. Returns true on success, false otherwise.
	 * \n
	 * ${arguments}
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * presideObjectService.syncOneToManyData(
	 * \t      sourceObject   = "event"
	 * \t    , sourceProperty = "sessions"
	 * \t    , sourceId       = rc.eventId
	 * \t    , targetIdList   = rc.sessions // e.g. "635,1,52,24"
	 * );
	 * ```
	 *
	 * @autodoc
	 * @sourceObject.hint   The object that contains the one-to-many property
	 * @sourceProperty.hint The name of the property that is defined as a one-to-many relationship
	 * @sourceId.hint       ID of the record whose related data we are to synchronize
	 * @targetIdList.hint   Comma separated list of IDs of records representing records in the related object
	 *
	 */
	public boolean function syncOneToManyData(
		  required string sourceObject
		, required string sourceProperty
		, required string sourceId
		, required string targetIdList
	) {
		var prop             = getObjectProperty( arguments.sourceObject, arguments.sourceProperty );
		var targetObjectName = prop.relatedTo ?: "";
		var targetObject     = getObject( targetObjectName );
		var targetFk         = prop.relationshipKey ?: arguments.sourceObject;
		var targetProp       = getObjectProperty( targetObjectName, targetFk );
		var records          = ListToArray( arguments.targetIdList );

		if ( !IsBoolean( targetProp.required ?: "" ) || !targetProp.required ) {
			var filter = "#targetObjectName#.#LCase( targetFk )# = :#targetObjectName#.#targetFk#";
			var params = { "#targetObjectName#.#targetFk#"=arguments.sourceId };

			if ( records.len() ) {
				filter &= " and #targetObjectName#.id not in (:#targetObjectName#.id)";
				params[ "#targetObjectName#.id" ] = records;
			}
			targetObject.updateData(
				  filter       = filter
				, filterParams = params
				, data         = { "#targetFk#" = "" }
			);
		}
		if ( records.len() ) {
			targetObject.updateData(
				  filter = { id=records }
				, data   = { "#targetFk#" = arguments.sourceId }
			);
		}

		return true;
	}

	/**
	 * Synchronizes a record's related one-to-many configurator object data for a given property. Returns true on success, false otherwise.
	 * \n
	 * ${arguments}
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * presideObjectService.syncOneToManyConfiguratorData(
	 * \t      sourceObject     = "event"
	 * \t    , sourceProperty   = "sessions"
	 * \t    , sourceId         = rc.eventId
	 * \t    , configuratorData = rc.configuratorData // serialized array of JSON objects, without surrounding []
	 * );
	 * ```
	 *
	 * @autodoc
	 * @sourceObject.hint     The object that contains the one-to-many property
	 * @sourceProperty.hint   The name of the property that is defined as a one-to-many relationship
	 * @sourceId.hint         ID of the record whose related data we are to synchronize
	 * @configuratorData.hint Comma separated JSON object strings representing records in the related object
	 *
	 */
	public boolean function syncOneToManyConfiguratorData(
		  required string  sourceObject
		, required string  sourceProperty
		, required string  sourceId
		, required string  configuratorData
		, required numeric versionNumber
	) {
		var prop             = getObjectProperty( arguments.sourceObject, arguments.sourceProperty );
		var targetObjectName = prop.relatedTo ?: "";
		var targetObject     = getObject( targetObjectName );
		var targetIdField    = targetObject.getIdField();
		var targetFk         = prop.relationshipKey ?: arguments.sourceObject;
		var records          = deserializeJSON( "[#configuratorData#]" );
		var existingIds      = [];
		var sort_order       = 0;
		var filter           = { "#targetObjectName#.#targetFk#"=sourceId };
		var extraFilters     = [];

		for( var record in records ) {
			record[ "sort_order" ] = ++sort_order;
			record[ targetFk ]     = sourceId;

			if ( len( record.id ?: "" ) ) {
				existingIds.append( record.id );
			}
		}

		if ( existingIds.len() ) {
			extraFilters.append({
				  filter       = "#targetObjectName#.#targetIdField# not in ( :#targetObjectName#.#targetIdField# )"
				, filterParams = { "#targetObjectName#.#targetIdField#"=existingIds }
			});
		}

		targetObject.deleteData(
			  filter       = filter
			, extraFilters = extraFilters
		);

		for (var record in records ) {
			if ( len( record.id ?: "" ) ) {
				targetObject.updateData(
					  id            = record.id
					, data          = record
					, versionNumber = versionNumber
				);
			} else {
				targetObject.insertData(
					  data          = record
					, versionNumber = versionNumber
				);
			}
		}

		return true;
	}

	/**
	 * Returns a structure of many to many data for a given record. Each structure key represents a many-to-many type property on the object. The value for each key will be a comma separated list of IDs of the related data.
	 * \n
	 * ${arguments}
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * relatedData = presideObjectService.getDeNormalizedManyToManyData(
	 * \t    objectName = "event"
	 * \t  , id         = rc.id
	 * );
	 * \n
	 * // the relatedData struct above might look like { tags = "C3635F77-D569-4D31-A794CA9324BC3E70,3AA27F08-819F-4C78-A8C5A97C897DFDE6" }
	 * ```
	 *
	 * @objectName.hint       Name of the object whose related data we wish to retrieve
	 * @id.hint               ID of the record whose related data we wish to retrieve
	 * @fromVersionTable.hint Whether or not to retrieve the data from the version history table for the object
	 * @specificVersion.hint  If retrieving from the version history, set a specific version number to retrieve
	 */
	public struct function getDeNormalizedManyToManyData(
		  required string  objectName
		, required string  id
		,          boolean fromVersionTable = false
		,          numeric specificVersion  = 0
		,          array   selectFields     = []
	) autodoc=true {
		var props          = getObjectProperties( arguments.objectName );
		var adapter        = getDbAdapterForObject( arguments.objectName );
		var escapedId      = adapter.escapeEntity( "id" );
		var manyToManyData = {};

		for( var prop in props ) {
			if ( ( !arguments.selectFields.len() || arguments.selectFields.findNoCase( prop ) ) ) {
				if ( isManyToManyProperty( arguments.objectName, prop ) ) {

					var idField = getIdField( props[ prop ].relatedTo ?: "" );
					var relatedVia = props[ prop ].relatedVia ?: "";
					var sortOrder = objectExists( relatedVia ) && StructKeyExists( getObjectProperties( relatedVia ), "sort_order" ) ? adapter.escapeEntity( "#relatedVia#.sort_order" ) : adapter.escapeEntity( "#prop#.#idField#" );
					var records = selectData(
						  objectName       = arguments.objectName
						, id               = arguments.id
						, selectFields     = [ adapter.escapeEntity( "#prop#.#idField#" ) & " as #escapedId#" ]
						, fromVersionTable = arguments.fromVersionTable
						, specificVersion  = arguments.specificVersion
						, orderBy          = sortOrder
					);

					manyToManyData[ prop ] = records.recordCount ? ValueList( records.id ) : "";
				} else if ( isOneToManyConfiguratorObject( arguments.objectName, prop ) ) {

					var property = getObjectProperty( arguments.objectName, prop );

					manyToManyData[ prop ] = getOneToManyConfiguratorJsonString(
						  sourceObject    = arguments.objectName
						, sourceId        = arguments.id
						, relatedTo       = property.relatedTo       ?: nullValue()
						, relationshipKey = property.relationshipKey ?: nullValue()
						, labelRenderer   = property.labelRenderer   ?: nullValue()
						, specificVersion = arguments.specificVersion
					);
				}
			}
		}

		return manyToManyData;
	}


	public string function getOneToManyConfiguratorJsonString(
		  required string sourceObject
		, required string sourceId
		,          string relatedTo
		,          string relationshipKey
		,          string labelRenderer
		,          string specificVersion
	) {
		var targetObject  = arguments.relatedTo       ?: "";
		var targetFk      = arguments.relationshipKey ?: arguments.sourceObject;
		var targetIdField = getIdField( targetObject );
		var useVersioning = Val( arguments.specificVersion ?: "" ) && objectIsVersioned( targetObject );
		var hasSortOrder  = StructKeyExists( getObjectProperties( targetObject ), "sort_order" );
		var orderBy       = hasSortOrder ? "sort_order" : "";
		var labelRenderer = arguments.labelRenderer ?: getObjectAttribute( targetObject, "labelRenderer" );
		var labelFields   = _getLabelRendererService().getSelectFieldsForLabel( labelRenderer );
		var values        = [];

		if ( Len( Trim( arguments.sourceId ) ) ) {
			var records = selectData(
				  objectName       = targetObject
				, filter           = { "#targetFk#"=arguments.sourceId }
				, selectFields     = labelFields.append( "#targetObject#.#targetIdField# as id" )
				, orderBy          = orderBy
				, useCache         = false
				, fromVersionTable = useVersioning
				, specificVersion  = Val( arguments.specificVersion ?: "" )
			);

			for( var record in records ) {
				var item = {
					  id       = record.id
					, __fromDb = true
					, __label  = _getLabelRendererService().renderLabel( labelRenderer=labelRenderer, args=record )
				};
				values.append( serializeJSON( item ) );
			}
			return ArrayToList( values );
		}

		return "";
	}

	/**
	 * Returns a summary query of all the versions of a given record (by ID),  optionally filtered by field name
	 *
	 * @objectName.hint Name of the object whose record we wish to retrieve the version history for
	 * @id.hint         ID of the record whose history we wish to view
	 * @fieldName.hint  Optional name of one of the object's property which which to filter the history. Doing so will show only versions in which this field changed.
	 *
	 */
	public any function getRecordVersions( required string objectName, required string id, string fieldName ) autodoc=true {
		var args = {};
		var idField = getIdField( arguments.objectName );

		for( var key in arguments ){ // we do this, because simply duplicating the arguments causes issues with the Argument type being more than a plain ol' structure
			args[ key ] = arguments[ key ];
		}

		args.objectName = getVersionObjectName( arguments.objectName );
		args.append( {
			  orderBy            = "_version_number desc"
			, useCache           = false
			, allowDraftVersions = true
		}, false );

		if ( StructKeyExists( args, "fieldName" ) ) {
			args.filter       = "#idField# = :#idField# and _version_changed_fields like :_version_changed_fields";
			args.filterParams = { "#idField#" = arguments.id, _version_changed_fields = "%,#args.fieldName#,%" };
			args.delete( "fieldName" );
			args.delete( "id" );
		}

		return selectData( argumentCollection = args );
	}

	/**
	 * Returns the version number of the previous version of the given record ID
	 * and existing version
	 *
	 * @autodoc             true
	 * @objectName.hint     Name of the object whose record we wish to retrieve the version history for
	 * @id.hint             ID of the record whose history we wish to view
	 * @currentVersion.hint Current version number
	 *
	 */
	public any function getPreviousVersion(
		  required string  objectName
		, required string  id
		, required numeric currentVersion
	) {
		var extraFilters = [{
			  filter = "_version_number < :_version_number"
			, filterParams = { _version_number=arguments.currentVersion }
		}];
		var prev = getRecordVersions(
			  argumentCollection = arguments
			, extraFilters       = extraFilters
			, maxRows            = 1
			, orderBy            = "_version_number desc"
			, selectFields       = [ "_version_number" ]
			, useCache           = true
		);

		return Val( prev._version_number );
	}

	/**
	 * Returns the version number of the next version of the given record ID
	 * and existing version
	 *
	 * @autodoc             true
	 * @objectName.hint     Name of the object whose record we wish to retrieve the version history for
	 * @id.hint             ID of the record whose history we wish to view
	 * @currentVersion.hint Current version number
	 *
	 */
	public numeric function getNextVersion(
		  required string  objectName
		, required string  id
		, required numeric currentVersion
	) {
		var extraFilters = [{
			  filter = "_version_number > :_version_number"
			, filterParams = { _version_number=arguments.currentVersion }
		}];
		var nxt = getRecordVersions(
			  argumentCollection = arguments
			, extraFilters       = extraFilters
			, maxRows            = 1
			, orderBy            = "_version_number asc"
			, selectFields       = [ "_version_number" ]
			, useCache           = true
		);

		return Val( nxt._version_number );
	}

	/**
	 * Performs a full database synchronisation with your Preside Data Objects. Creating new tables, fields and relationships as well
	 * as modifying and retiring existing ones.
	 * \n
	 * >>> You are unlikely to need to call this method directly.
	 */
	public void function dbSync() autodoc=true {
		_announceInterception( "preDbSyncObjects" );

		_getSqlSchemaSynchronizer().synchronize(
			  dsns    = _getDsns()
			, objects = _getObjects()
		);

		_announceInterception( "postDbSyncObjects" );
	}

	/**
	 * Reloads all the object definitions by reading them all from file.
	 * \n
	 * >>> You are unlikely to need to call this method directly.
	 */
	public void function reload() autodoc=true {
		StructClear( _getSimpleLocalCache() );
		_clearAllQueryCaches();
		_setObjects({});
		_loadObjects();
	}

	/**
	 * Returns an array of names for all of the registered objects, sorted alphabetically (ignoring case)
	 */
	public array function listObjects( boolean includeGeneratedObjects=false ) autodoc=true {
		var objects     = _getObjects();
		var objectNames = [];

		for( var objectName in objects ){
			if ( arguments.includeGeneratedObjects || !IsSimpleValue( objects[ objectName ].instance ?: "" ) ) {
				objectNames.append( objectName );
			}
		}

		ArraySort( objectNames, "textnocase" );

		return objectNames;
	}

	/**
	 * Returns whether or not the passed object name has been registered
	 *
	 * @objectName.hint Name of the object that you wish to check the existance of
	 */
	public boolean function objectExists( required string objectName ) autodoc=true {
		var objects = _getObjects();

		return StructKeyExists( objects, arguments.objectName );
	}

	/**
	 * Returns whether or not the object has been automatically created by the system
	 *
	 * @objectName.hint Name of the object that you wish to check
	 */
	public boolean function objectIsAutoGenerated( required string objectName ) autodoc=true {
		var obj = _getObject( arguments.objectName );

		return IsSimpleValue( obj.instance );
	}

	/**
	 * Returns whether or not the passed field exists on the passed object
	 *
	 * @objectName.hint Name of the object whose field you wish to check
	 * @fieldName.hint  Name of the field you wish to check the existance of
	 */
	public boolean function fieldExists( required string objectName, required string fieldName ) autodoc=true {
		var obj = _getObject( arguments.objectName );

		return StructKeyExists( obj.meta.properties, arguments.fieldName );
	}

	/**
	 * Returns the ID field name of the object
	 *
	 * @autodoc    true
	 * @objectName Name of the object whose ID field you wish to get
	 */
	public string function getIdField( required string objectName ) {
		return getObjectAttribute( arguments.objectName, "idField", "id" );
	}

	/**
	 * Returns the label field name of the object
	 *
	 * @autodoc    true
	 * @objectName Name of the object whose label field you wish to get
	 */
	public string function getLabelField( required string objectName ) {
		var noLabel = getObjectAttribute( arguments.objectName, "noLabel", "" );

		if ( IsBoolean( noLabel ) && noLabel ) {
			return "";
		}

		return getObjectAttribute( arguments.objectName, "labelField", "label" );
	}

	/**
	 * Returns the dateCreated field name of the object
	 *
	 * @autodoc    true
	 * @objectName Name of the object whose dateCreated field you wish to get
	 */
	public string function getDateCreatedField( required string objectName ) {
		var noDateCreated = getObjectAttribute( arguments.objectName, "noDateCreated", "" );

		if ( IsBoolean( noDateCreated ) && noDateCreated ) {
			return "";
		}

		return getObjectAttribute( arguments.objectName, "dateCreatedField", "dateCreated" );
	}

	/**
	 * Returns the dateModified field name of the object
	 *
	 * @autodoc    true
	 * @objectName Name of the object whose dateModified field you wish to get
	 */
	public string function getDateModifiedField( required string objectName ) {
		var noDateModified = getObjectAttribute( arguments.objectName, "noDateModified", "" );

		if ( IsBoolean( noDateModified ) && noDateModified ) {
			return "";
		}

		return getObjectAttribute( arguments.objectName, "dateModifiedField", "dateModified" );
	}

	/**
	 * Returns an arbritary attribute value that is defined on the object's :code:`component` tag.
	 * \n
	 * ${arguments}
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * eventLabelField = presideObjectService.getObjectAttribute(
	 * \t      objectName    = "event"
	 * \t    , attributeName = "labelField"
	 * \t    , defaultValue  = "label"
	 * );
	 * ```
	 *
	 * @objectName.hint    Name of the object whose attribute we wish to get
	 * @attributeName.hint Name of the attribute whose value we wish to get
	 * @defaultValue.hint  Default value for the attribute, should it not exist
	 *
	 */
	public any function getObjectAttribute( required string objectName, required string attributeName, string defaultValue="" ) autodoc=true {
		var obj = _getObject( arguments.objectName );

		return obj.meta[ arguments.attributeName ] ?: arguments.defaultValue;
	}

	/**
	 * Returns an arbritary attribute value that is defined on a specified property for an object.
	 * \n
	 * ${arguments}
	 * \n
	 * ## Example
	 * \n
	 * ```luceescript
	 * maxLength = presideObjectService.getObjectPropertyAttribute(
	 * \t      objectName    = "event"
	 * \t    , propertyName  = "name"
	 * \t    , attributeName = "maxLength"
	 * \t    , defaultValue  = 200
	 * );
	 * ```
	 *
	 * @objectName.hint    Name of the object whose property attribute we wish to get
	 * @propertyName.hint  Name of the property whose attribute we wish to get
	 * @attributeName.hint Name of the attribute whose value we wish to get
	 * @defaultValue.hint  Default value for the attribute, should it not exist
	 *
	 */
	public string function getObjectPropertyAttribute( required string objectName, required string propertyName, required string attributeName, string defaultValue="" ) autodoc=true {
		var obj = _getObject( arguments.objectName );

		return obj.meta.properties[ arguments.propertyName ][ arguments.attributeName ] ?: arguments.defaultValue;
	}


	/**
	 * This method, returns the object name that can be used to reference the version history object
	 * for a given object.
	 *
	 * @sourceObjectName.hint Name of the object whose version object name we wish to retrieve
	 */
	public string function getVersionObjectName( required string sourceObjectName ) autodoc=true {
		var obj = _getObject( arguments.sourceObjectName );

		return obj.meta.versionObjectName ?: "";
	}

	/**
	 * Returns whether or not the given object is using the versioning system
	 *
	 * @objectName.hint Name of the object you wish to check
	 */
	public boolean function objectIsVersioned( required string objectName ) autodoc=true {
		var obj = _getObject( objectName );

		return IsBoolean( obj.meta.versioned ?: "" ) && obj.meta.versioned;
	}

	/**
	 * Returns whether or not the given object is configured to create
	 * versions on insert
	 *
	 * @objectName.hint Name of the object you wish to check
	 */
	public boolean function versioningRequiredOnInsert( required string objectName ) {
		var versionOnInsert = getObjectAttribute( arguments.objectName, "versionOnInsert" );

		return !IsBoolean( versionOnInsert ) || versionOnInsert;
	}

	/**
	 * Returns the next available version number that can
	 * be used for saving a new version record.
	 * \n
	 * This is an auto incrementing integer that is global to all versioning tables
	 * in the system.
	 */
	public numeric function getNextVersionNumber() autodoc=true {
		return _getVersioningService().getNextVersionNumber();
	}

	public any function getObjectProperties( required string objectName ) {
		return _getObject( arguments.objectName ).meta.properties;
	}

	public any function getObjectProperty( required string objectName, required string propertyName ) {
		var props = _getObject( arguments.objectName ).meta.properties;

		if ( StructKeyExists( props, arguments.propertyName ) ) {
			return props[ arguments.propertyName ];
		}

		for( var propName in props ) {
			var prop = props[ propName ];
			if ( ListFindNoCase( prop.aliases ?: "", arguments.propertyName ) ) {
				return prop;
			}
		}

		if ( ListLen( arguments.propertyName, "." ) > 1 ) {
			return getObjectProperty( propertyName=ListRest( arguments.propertyName, "." ), objectName=_resolveObjectNameFromColumnJoinSyntax(
				  startObject = arguments.objectName
				, joinSyntax  = ListFirst( arguments.propertyName, "." )
			) );
		}

		throw(
			  type    = "preside.object.property.not.found"
			, message = "The property, [#arguments.propertyName#], is not defined on the [#arguments.objectName#] object"
		);
	}

	public boolean function isPageType( required string objectName ) {
		var objMeta = _getObject( arguments.objectName ).meta;

		return IsBoolean( objMeta.isPageType ?: "" ) && objMeta.isPageType;
	}

	public string function getResourceBundleUriRoot( required string objectName ) {
		if ( objectExists( arguments.objectName ) ) {
			return ( isPageType( arguments.objectName ) ? "page-types" : "preside-objects" ) & ".#arguments.objectName#:";
		}
		return "cms:";
	}

	public boolean function isManyToManyProperty( required string objectName, required string propertyName ) {
		return getObjectPropertyAttribute( arguments.objectName, arguments.propertyName, "relationship", "" ) == "many-to-many";
	}

	public any function getDbAdapterForObject( required string objectName ) {
		var obj = _getObject( arguments.objectName ).meta;

		return _getAdapter( obj.dsn );
	}

	public array function listForeignObjectsBlockingDelete( required string objectName, required any recordId ) {
		var obj   = _getObject( objectName=arguments.objectName );
		var joins = _getRelationshipGuidance().getObjectRelationships( arguments.objectName );
		var foreignObjName  = "";
		var join  = "";
		var blocking = [];
		var filter = {};
		var recordCount = 0;
		var relatedKey = "";

		for( foreignObjName in joins ){
			for( join in joins[ foreignObjName ] ) {
				if ( join.type == "one-to-many" && join.ondelete == "error" ) {
					filter = { "#join.fk#" = arguments.recordId };
					recordCount = selectData( objectName=foreignObjName, selectFields=["count(*) as record_count"], filter=filter, useCache=false ).record_count;

					if ( Val( recordCount ) ) {
						ArrayAppend( blocking, { objectName=foreignObjName, recordcount=recordcount, fk=join.fk } );
					}
				}
			}
		}

		return blocking;
	}

	public numeric function deleteRelatedData( required string objectName, required any recordId ) {
		var blocking       = listForeignObjectsBlockingDelete( argumentCollection = arguments );
		var totalDeleted   = 0;
		var blocker        = "";

		transaction {
			try {
				for( blocker in blocking ){
					totalDeleted += deleteData(
						  objectName = blocker.objectName
						, filter     = { "#blocker.fk#" = arguments.recordId }
					);
				}
			} catch( database e ) {
				throw(
					  type    = "PresideObjectService.CascadeDeleteTooDeep"
					, message = "A cascading delete of a [#arguments.objectName#] record was prevented due to too many levels of cascade."
					, detail  = "Preside will only allow a single level of cascaded deletes"
				);
			}
		}

		return totalDeleted;
	}

	public string function getDefaultFormControlForPropertyAttributes(
		  string  type         = "string"
		, string  dbType       = "varchar"
		, string  relationship = "none"
		, string  relatedTo    = ""
		, string  enum         = ""
		, numeric maxLength    = 0
		, string  formula      = ""
	) {
		if ( Len( Trim( formula ) ) ) {
			return "none";
		}

		switch( arguments.relationship ){
			case "many-to-one" :
				switch( arguments.relatedTo ) {
					case "page"  : return "siteTreePagePicker";
					case "asset" : return "assetPicker";
					case "link"  : return "linkPicker";
					default      : return "manyToOneSelect";
				}
			case "many-to-many":
				switch( arguments.relatedTo ) {
					case "page"  : return "siteTreePagePicker";
					case "asset" : return "assetPicker";
					case "link"  : return "MultiLinkPicker";
					default      : return "manyToManySelect";
				}
			case "one-to-many":
				if ( isOneToManyConfiguratorObject( arguments.relatedTo ) ) {
					return "oneToManyConfigurator";
				}
				return "oneToManyManager";
		}

		if ( arguments.enum.len() ) {
			return "enumSelect";
		}

		switch ( arguments.type ) {
			case "numeric":
				return "spinner";
			case "boolean":
				return "yesNoSwitch";
		}

		switch( arguments.dbType ){
			case "text":
			case "longtext":
			case "clob":
				return "richeditor";
			case "date":
				return "datePicker";
			case "datetime":
				return "dateTimePicker";
		}

		if ( maxLength gte 200 ) {
			return "textarea";
		}

		return "textinput";
	}

	public string function mergeFilters( required any filter1, required any filter2, required any dbAdapter, required string tableAlias ) {
		var parsed1 = arguments.dbAdapter.getClauseSql( arguments.filter1, arguments.tableAlias );
		var parsed2 = arguments.dbAdapter.getClauseSql( arguments.filter2, arguments.tableAlias );

		parsed1 = ReReplace( parsed1, "^\s*where ", "" );
		parsed2 = ReReplace( parsed2, "^\s*where ", "" );

		if ( Len( Trim( parsed1 ) ) && Len( Trim( parsed2 ) ) ) {
			return "(" & parsed1 & ") and (" & parsed2 & ")";
		}

		return Len( Trim( parsed1 ) ) ? parsed1 : parsed2;
	}

	/**
	 * Clears related selectData caches
	 * for the given object and optional filters
	 *
	 * @autodoc
	 */
	public void function clearRelatedCaches(
		  required string  objectName
		,          any     filter                  = ""
		,          struct  filterParams            = {}
		,          boolean clearSingleRecordCaches = true
	) {
		_announceInterception( "preClearRelatedCaches", arguments );

		var cacheMap              = _getCacheMap();
		var relatedObjectsToClear = StructKeyArray( cachemap[ arguments.objectName ] ?: {} );

		if ( $isFeatureEnabled( "queryCachePerObject" ) ) {
			return _clearRelatedCachesWithQueryCachePerObject( argumentCollection=arguments, relatedObjectsToClear=relatedObjectsToClear );
		}

		var cache                 = _getDefaultQueryCache();
		var idField               = getIdField( objectName );
		var keyPrefixes           = [ LCase( "#arguments.objectName#.complex_" ) ];
		var recordIds             = [];

		for( var relatedObject in relatedObjectsToClear ) {
			keyPrefixes.append( LCase( "#relatedObject#." ) );
		}

		if ( IsStruct( arguments.filter ) and StructKeyExists( arguments.filter, "id" ) ) {
			recordIds = arguments.filter.id;
		} else if ( IsStruct( arguments.filter ) and StructKeyExists( arguments.filter, idField ) ) {
			recordIds = arguments.filter[ idField ];
		} else if ( IsStruct( arguments.filter ) and StructKeyExists( arguments.filter, "#arguments.objectName#.id" ) ) {
			recordIds = arguments.filter[ "#arguments.objectName#.id" ];
		} else if ( IsStruct( arguments.filter ) and StructKeyExists( arguments.filter, "#arguments.objectName#.#idField#" ) ) {
			recordIds = arguments.filter[ "#arguments.objectName#.#idField#" ];
		} else if ( StructKeyExists( arguments.filterParams, "id" ) ) {
			recordIds = arguments.filterParams.id;
		} else if ( StructKeyExists( arguments.filterParams, idField ) ) {
			recordIds = arguments.filterParams[ idField ];
		}

		if ( IsSimpleValue( recordIds ) ) {
			recordIds = ListToArray( recordIds );
		} else if ( IsStruct( recordIds ) ) {
			if ( Len( Trim( recordIds.value ?: "" ) ) ) {
				recordIds = ( recordIds.list ?: false ) ? ListToArray( recordIds.value, recordIds.separator ?: "," ) : [ recordIds.value ];
			} else {
				recordIds = [];
			}
		}

		if ( ArrayLen( recordIds ) ) {
			for( var recordId in recordIds ) {
				keyPrefixes.append( LCase( "#arguments.objectName#.single.#recordId#_" ) );
			}
		} else if ( arguments.clearSingleRecordCaches ) {
			keyPrefixes.append( LCase( "#arguments.objectName#.single." ) );
		}

		var cacheKeys = cache.getKeys();

		if ( !ArrayLen( cacheKeys ) ) {
			_announceInterception( "postClearRelatedCaches", arguments );
			return;
		}

		ArraySort( cacheKeys, "text" );
		ArraySort( keyPrefixes, "text" );
		for( var prefix in keyPrefixes ) {
			var startPos = _seekStartPosWithBinarySort( prefix, cacheKeys );

			if ( !startPos ) {
				continue;
			}

			var deleted   = [];
			var keyLen    = ArrayLen( cacheKeys );
			var prefixLen = Len( prefix );

			for( var i=startPos; i<=keyLen; i++ ) {
				var comparison = Compare( Left( cacheKeys[ i ], prefixLen ), prefix );

				if ( comparison == 0 ) {
					try {
						deleted.append( i );
						cache.clearQuiet( cacheKeys[ i ] );
					} catch( any e ) {
						// do nothing, multiple processes could attempt clearing the same key
					}
				} else if ( comparison == 1 ) {
					break;
				}
			}

			for( var i=ArrayLen( deleted ); i>0; i-- ) {
				ArrayDeleteAt( cacheKeys, deleted[ i ] );
			}
			if ( !ArrayLen( cacheKeys ) ) {
				break;
			}
		}

		_announceInterception( "postClearRelatedCaches", arguments );

		var derivedFrom = getObjectAttribute( arguments.objectName, "derivedFrom", "" );
		if ( Len( Trim( derivedFrom ) ) ) {
			clearRelatedCaches( argumentCollection=arguments, objectName=derivedFrom );
		}
	}


	public boolean function isOneToManyConfiguratorObject( required string objectName, string propertyName ) {
		var prop             = len( arguments.propertyName ?: "" ) ? getObjectProperty( arguments.objectName, arguments.propertyName ) : "";
		var relationship     = prop.relationship ?: "";
		var targetObjectName = prop.relatedTo    ?: "";
		var configurator     = false;

		if ( !len( arguments.propertyName ?: "" ) ) {
			configurator = getObjectAttribute( arguments.objectName, "oneToManyConfigurator", false );
		} else if ( relationship == "one-to-many" ) {
			configurator = getObjectAttribute( targetObjectName, "oneToManyConfigurator", false );
		}

		return IsBoolean( configurator ) && configurator;
	}

	public array function parseSelectFields(
		  required string  objectName
		, required array   selectFields
		,          array   extraSelectFields       = []
		,          boolean includeAlias            = true
		,          boolean includeAllFormulaFields = false
	) {
		_announceInterception( "preParseSelectFields", arguments );
		var fields  = arguments.selectFields;
		var obj     = _getObject( arguments.objectName ).meta;
		var adapter = _getAdapter( obj.dsn ?: "" );

		if ( !fields.len() ) {
			fields = _dbFieldListToSelectFieldsArray( obj.dbFieldList, arguments.objectName, adapter );
		}

		for( var i=1; i <=fields.len(); i++ ){
			var objName = "";
			var match   = ReFindNoCase( "([\S]+\.)?\$\{labelfield\}", fields[i], 1, true );

			match = match.len[1] ? Mid( fields[i], match.pos[1], match.len[1] ) : "";

			if ( Len( Trim( match ) ) ) {
				var labelField = "";
				if ( ListLen( match, "." ) == 1 ) {
					objName = arguments.objectName;
				} else {
					objName = _resolveObjectNameFromColumnJoinSyntax( startObject=arguments.objectName, joinSyntax=ListFirst( match, "." ) );
				}

				labelField = getObjectAttribute( objName, "labelfield", "label" );
				if ( !Len( labelField ) ) {
					throw( type="PresideObjectService.no.label.field", message="The object [#objName#] has no label field" );
				}

				if ( ListLen( labelField, "." ) > 1 ) {
					fields[i] = Replace( fields[i], "#arguments.objectName#.${labelfield}", "${labelfield}", "all" );
					fields[i] = Replace( fields[i], ".${labelfield}", "$${labelfield}", "all" );
				}
				fields[i] = Replace( fields[i], "${labelfield}", labelField, "all" );
			}

			fields[i] = expandFormulaFields(
				  objectName = arguments.objectName
				, expression = fields[i]
				, dbAdapter  = adapter
				, includeAlias = arguments.includeAlias
			);

			if ( arguments.includeAlias ) {
				fields[i] = _autoPrefixBareProperty(
					  objectName   = arguments.objectName
					, propertyName = fields[i]
					, dbAdapter    = adapter
				);
			}
		}

		arguments.selectFields = fields;

		if ( arguments.includeAllFormulaFields ) {
			arguments.extraSelectFields.append( listToArray( obj.formulaFieldList ?: "" ), true );
		}
		if ( arguments.extraSelectFields.len() ) {
			var extraFields = parseSelectFields(
				  objectName   = arguments.objectName
				, selectFields = arguments.extraSelectFields
				, includeAlias = arguments.includeAlias
			);
			arguments.selectFields.append( extraFields, true);
		}
		_announceInterception( "postParseSelectFields", arguments );

		return fields;
	}

	public string function expandFormulaFields(
		  required string  objectName
		, required string  expression
		,          any     dbAdapter    = getDbAdapterForObject( arguments.objectName )
		,          boolean includeAlias = true
	) {
		var props                = getObjectProperties( arguments.objectName );
		var expanded             = arguments.expression;
		var expressionMinusAlias = ListFirst( arguments.expression, " " );
		var propertyName         = expressionMinusAlias;
		var alias                = ListRest( arguments.expression, " " );
		var prefix               = "";
		var relatedObjectName    = "";

		if ( ListLen( expressionMinusAlias, "." ) == 2 ) {
			propertyName = ListLast( expressionMinusAlias, "." );
			if ( ListFirst( expressionMinusAlias, "." ) != arguments.objectName ) {
				prefix            = ListFirst( expressionMinusAlias, "." );
				relatedObjectName = _resolveObjectNameFromColumnJoinSyntax( arguments.objectName, prefix );

				if ( objectExists( relatedObjectName ) ) {
					props = getObjectProperties( relatedObjectName );
				}
			} else {
				prefix = "";
			}
		}

		var formula = props[ propertyName ].formula ?: "";

		if ( Len( Trim( formula ) ) ) {
			if ( formula.findNoCase( "${prefix}" ) ) {
				if ( prefix.len() ) {
					formula = formula.reReplaceNoCase( "\$\{prefix\}(\S+)?\.", "${prefix}$\1.", "all" );
					formula = formula.reReplaceNoCase( "\$\{prefix\}([^\$])" , "${prefix}.\1", "all" );
				} else {
					formula = formula.reReplaceNoCase( "\$\{prefix\}(\S+)?\.", "\1.", "all" );
					formula = formula.reReplaceNoCase( "\$\{prefix\}([^\$])" , "#arguments.objectName#.\1", "all" );
				}
				formula = formula.replaceNoCase( "${prefix}", prefix, "all" );
			}

			if ( arguments.includeAlias && !alias.len() ) {
				expanded = formula & " as #dbAdapter.escapeEntity( propertyName )#";
			} else {
				expanded = formula;
			}

			if ( alias.len() ) {
				expanded &= " #alias#";
			}
		}


		return expanded;
	}

	public string function slugify() {
		return $slugify( argumentCollection=arguments );
	}

	public any function getCacheStats() {
		var cachstats = "";
		var config = "";
		var stats     = {
			  objects     = 0
			, hits        = 0
			, misses      = 0
			, evictions   = 0
			, gcs         = 0
			, lastReap    = '1900-01-01'
			, performance = 0
			, maxObjects  = 0
		};

		if ( $isFeatureEnabled( "queryCachePerObject" ) ) {
			var caches = variables._objectQueryCaches ?: {};

			for( var cacheName in caches ) {
				cacheStats = caches[ cacheName ].getStats();
				config     = caches[ cacheName ].getConfiguration();

				stats.objects    += cacheStats.getObjectCount();
				stats.hits       += cacheStats.getHits();
				stats.misses     += cacheStats.getMisses();
				stats.evictions  += cacheStats.getEvictionCount();
				stats.gcs        += cacheStats.getGarbageCollections();
				stats.maxObjects += Val( config.maxObjects ?: 0 );

				if ( cacheStats.getLastReapDatetime() > stats.lastReap ) {
					stats.lastReap = cacheStats.getLastReapDatetime();
				}
			}
		} else {
			cachstats = _getDefaultQueryCache().getStats();

			stats.objects   = cacheStats.getObjectCount();
			stats.hits      = cacheStats.getHits();
			stats.misses    = cacheStats.getMisses();
			stats.evictions = cacheStats.getEvictionCount();
			stats.gcs       = cacheStats.getGarbageCollections();
			stats.lastReap  = cacheStats.getLastReapDatetime();
		}

		stats.totalRequests = stats.hits + stats.misses;

		if ( stats.totalRequests ) {
			stats.performance = ( stats.hits / stats.totalRequests ) * 100;
		}

		return stats;
	}

// PRIVATE HELPERS
	private void function _loadObjects() {
		var objectPaths = _getAllObjectPaths();

		_announceInterception( state="preLoadPresideObjects", interceptData={ objectPaths=objectPaths } );

		var objects = _getObjectReader().readObjects( objectPaths );
		var dsns    = {};

		for( var objName in objects ){
			dsns[ objects[ objName ].meta.dsn ] = 1
		}

		if ( StructCount( objects ) ) {
			_getRelationshipGuidance().setupRelationships( objects );
			_getVersioningService().setupVersioningForVersionedObjects( objects, StructKeyArray( dsns )[1] );
		}

		_ensureValidDbEntityNames( objects );
		_setObjects( objects );
		_setDsns( StructKeyArray( dsns ) );
		_setupAliasCache();

		_announceInterception( state="postLoadPresideObjects", interceptData={ objects=objects } );
	}

	private void function _ensureValidDbEntityNames( required struct objects ) {
		for( var objectName in arguments.objects ) {
			var objMeta = arguments.objects[ objectName ].meta ?: {};
			var adapter = _getAdapter( objMeta.dsn ?: "" );
			var maxTableNameLength = adapter.getTableNameMaxLength();

			if ( Len( objMeta.tableName ?: "" ) > maxTableNameLength ) {
				if ( _getThrowOnLongTableName() ) {
					throw( type="PresideObjectService.invalidTableName", message="Table name is too long", detail="The table name, [#objMeta.tableName#], is longer than the maximum [#maxTableNameLength# characters] allowed by the database." );
				}

				objMeta.tableName = Left( objMeta.tableName, maxTableNameLength );
			}
		}
	}

	private void function _setupAliasCache() {
		var objects    = _getObjects();
		var aliasCache = {};

		for( var objName in objects ) {
			var obj   = objects[ objName ];
			var props = obj.meta.properties;
			for( var propName in props ) {
				var aliases = Trim( props[ propName ].aliases ?: "" ).listToArray();

				for( var alias in aliases ) {
					aliasCache[ objName ] = aliasCache[ objName ] ?: {};
					aliasCache[ objName ][ alias ] = propName;
				}
			}
		}

		_setAliasCache( aliasCache );
	}

	private string function _getCacheKey( required string objectName, any filter="", struct filterParams={} ) {
		var cacheKey = arguments.objectName;

		if ( !$isFeatureEnabled( "queryCachePerObject" ) ) {
			var idField     = getIdField( arguments.objectName );
			var fullIdField = "#arguments.objectName#.#idField#";
			var recordId    = "";
			var isComplex   = ( IsStruct( arguments.filter ) && StructCount( arguments.filter ) > 1 )
			                  || StructCount( arguments.filterParams ) > 1;

			if ( !isComplex ) {
				if ( IsStruct( arguments.filter ) ) {
					if ( StructKeyExists( arguments.filter, "id" ) ) {
						recordId = arguments.filter.id;
					} else if ( StructKeyExists( arguments.filter, idField ) ) {
						recordId = arguments.filter[ idField ];
					} else if ( StructKeyExists( arguments.filter, fullIdField ) ) {
						recordId = arguments.filter[ fullIdField ];
					} else if ( StructKeyExists( arguments.filter, "#arguments.objectName#.id" ) ) {
						recordId = arguments.filter[ "#arguments.objectName#.id" ];
					} else {
						isComplex = true;
					}
				} else {
					if ( StructKeyExists( arguments.filterParams, "id" ) ) {
						recordId = arguments.filterParams.id;
					} else if ( StructKeyExists( arguments.filterParams, idField ) ) {
						recordId = arguments.filterParams[ idField ];
					} else if ( StructKeyExists( arguments.filterParams, fullIdField ) ) {
						recordId = arguments.filterParams[ fullIdField ];
					} else if ( StructKeyExists( arguments.filterParams, "#arguments.objectName#.id" ) ) {
						recordId = arguments.filterParams[ "#arguments.objectName#.id" ];
					} else {
						isComplex = true;
					}
				}
			}

			if ( IsStruct( recordId ) ) {
				if ( Len( Trim( recordId.value ?: "" ) ) ) {
					recordId = ( recordId.list ?: false ) ? ListToArray( recordId.value, recordId.separator ?: "," ) : recordId.value;
				} else {
					isComplex = true;
				}
			}

			if ( IsArray( recordId ) ) {
				var recordIdCount = ArrayLen( recordId );
				if ( !recordIdCount || recordIdCount > 1 ) {
					isComplex = true;
				} else {
					recordId = recordId[ 1 ];
				}
			}

			if ( isComplex ) {
				cacheKey &= ".complex";
			} else {
				cacheKey &= ".single.#recordId#";
			}
		}

		cacheKey &= "_" & Hash( LCase( Serialize( arguments ) ) );

		return cacheKey;
	}

	private struct function _getObject( required string objectName ) {
		var objects = _getObjects();

		if ( not StructKeyExists( objects, arguments.objectName ) ) {
			throw( type="PresideObjectService.missingObject", message="Object [#arguments.objectName#] does not exist" );
		}

		return objects[ arguments.objectName ];
	}

	private array function _getAllObjectPaths() {
		var dirs        = _getObjectDirectories();
		var dir         = "";
		var dirExpanded = "";
		var files       = "";
		var file        = "";
		var paths       = [];
		var path        = "";
		for( dir in dirs ) {
			files = DirectoryList( path=dir, recurse=true, filter="*.cfc" );
			dirExpanded = ExpandPath( dir );

			for( file in files ) {
				path = dir & Replace( file, dirExpanded, "" );
				path = ListDeleteAt( path, ListLen( path, "." ), "." );
				path = ListChangeDelims( path, "/", "\" );

				ArrayAppend( paths, path );
			}
		}

		return paths;
	}

	private array function _convertDataToQueryParams( required string objectName, required struct columnDefinitions, required struct data, required any dbAdapter, string prefix="", string tableAlias="" ) {
		var key        = "";
		var params     = [];
		var param      = "";
		var objName = "";
		var cols       = "";
		var i          = 0;
		var paramName  = "";
		var dataType   = "";

		for( key in arguments.data ){
			if ( ListLen( key, "." ) == 2 && ListFirst( key, "." ) != arguments.tableAlias ) {

				objName = _resolveObjectNameFromColumnJoinSyntax( startObject = arguments.objectName, joinSyntax = ListFirst( key, "." ) );

				if ( objectExists( objName ) ) {
					cols = _getObject( objName ).meta.properties;
				}
			} else {
				cols = arguments.columnDefinitions;
			}

			paramName = arguments.prefix & ReReplace( key, "[\.\$]", "__", "all" );
			dataType  = arguments.dbAdapter.sqlDataTypeToCfSqlDatatype( cols[ ListLast( key, "." ) ].dbType );

			if ( !StructKeyExists( arguments.data, key ) ) { // should use IsNull() arguments.data[key] but bug in Railo prevents this
				param = {
					  name  = paramName
					, value = NullValue()
					, type  = dataType
					, null  = true
				};

				ArrayAppend( params, param );
			} else if ( IsArray( arguments.data[ key ] ) ) {
				param = {
					  name      = paramName
					, value     = ArrayToList( arguments.data[ key ], chr( 31 ) )
					, type      = dataType
					, list      = true
					, separator = chr( 31 )
				};

				ArrayAppend( params, param );

			} else {
				param = {
					  name  = paramName
					, value = arguments.data[ key ]
					, type  = dataType
				};

				ArrayAppend( params, param );
			}

		}

		return params;
	}

	private array function _convertUserFilterParamsToQueryParams( required struct columnDefinitions, required struct params, required any dbAdapter, required string objectName ) {
		var key        = "";
		var params     = [];
		var param      = "";
		var cols       = "";
		var i          = 0;
		var paramName  = "";
		var dataType   = "";

		for( key in arguments.params ){
			param     = arguments.params[ key ];
			paramName = ReReplace( key, "[\.\$]", "__", "all" );

			if ( IsStruct( param ) ) {
				StructAppend( param, { name=paramName } );
			} else {
				param = {
					  name  = paramName
					, value = param
				};
			}

			if ( !IsNull( param.value ) && IsArray( param.value ) ) {
				param.value     = ArrayToList( param.value, chr( 31 ) );
				param.list      = true;
				param.separator = chr( 31 );
			}

			if ( not StructKeyExists( param, "type" ) ) {
				if ( ListLen( key, "." ) eq 2 ) {
					var paramObjectName = _resolveObjectNameFromColumnJoinSyntax( startObject=arguments.objectName, joinSyntax=ListFirst( key, "." ) );
					cols = _getObject( paramObjectName ).meta.properties;

				} else {
					cols = arguments.columnDefinitions;
				}

				param.type = arguments.dbAdapter.sqlDataTypeToCfSqlDatatype( cols[ ListLast( key, "." ) ].dbType );
			}

			ArrayAppend( params, param );
		}

		return params;
	}

	private array function _extractForeignObjectsFromArguments(
		  required string objectName
		,          struct preparedFilter = {}
		,          struct data           = {}
		,          array  selectFields   = []
		,          string orderBy        = ""
		,          array  extraJoins     = []
		,          array  extraFilters   = []

	) {
		var filter     = arguments.preparedFilter.filter ?: "";
		var having     = arguments.preparedFilter.having ?: "";
		var cache      = _getSimpleLocalCache();
		var cacheKey   = _generateForeignObjectsCacheKey( argumentCollection=arguments );

		if ( StructKeyExists( cache, cacheKey ) ) {
			return cache[ cacheKey ];
		}

		var key        = "";
		var all        = Duplicate( arguments.data );
		var fieldRegex = _getAlaisedFieldRegex();
		var entities   = _getEntityNames();
		var field      = "";
		var objects    = {}
		var addMatches = function( required string input ){
			var matches = _reSearch( fieldRegex, arguments.input );
			if ( StructKeyExists( matches, "$2" ) ) {
				for( var match in matches.$2 ){
					var matchEntities = match.listToArray( "$" );
					var matched       = true;

					for( var entity in matchEntities ) {
						if ( !StructKeyExists( entities, entity ) ) {
							matched = false;
							break;
						}
					}

					if ( matched ) {
						objects[ match ] = 1;
					}
				}
			}
		};

		if ( IsStruct( filter ) ) {
			StructAppend( all, filter );
		}

		for( key in all ) {
			if ( ListLen( key, "." ) eq 2 ) {
				objects[ ListFirst( key, "." ) ] = 1;
			}
		}

		for( field in arguments.selectFields ){
			addMatches( field );
		}
		for( field in ListToArray( arguments.orderBy ) ){
			addMatches( ListFirst( field, " " ) );
		}
		if ( isSimpleValue( filter ) ) {
			addMatches( filter );
		}
		if ( Len( Trim( having ) ) ) {
			addMatches( having );
		}

		for( var join in extraJoins ) {
			addMatches( "#( join.joinToTable ?: '' )#.#( join.joinToColumn ?: '' )#" );
		}
		for( var extraFilter in extraFilters ) {
			if ( IsArray( extraFilter.extraJoins ?: "" ) ) {
				for( var join in extraFilter.extraJoins ) {
					addMatches( "#( join.joinToTable ?: '' )#.#( join.joinToColumn ?: '' )#" );
				}
			}
		}

		StructDelete( objects, arguments.objectName );
		objects = StructKeyArray( objects );

		cache[ cacheKey ] = objects;
		if ( ArrayLen( objects ) ) {
			var cacheMap = _getCacheMap();
			for( var relatedObject in objects ) {
				relatedObject = _resolveObjectNameFromColumnJoinSyntax( arguments.objectName, relatedObject );
				cacheMap[ relatedObject ] = cacheMap[ relatedObject ] ?: {};
				cacheMap[ relatedObject ][ arguments.objectName ] = 1;
			}
		}

		return objects;
	}

	private string function _generateForeignObjectsCacheKey(
		  required string objectName
		,          struct preparedFilter = {}
		,          struct data           = {}
		,          array  selectFields   = []
		,          string orderBy        = ""
		,          array  extraJoins     = []
		,          array  extraFilters   = []
	) {
		var filter   = arguments.preparedFilter.filter ?: "";
		var having   = arguments.preparedFilter.having ?: "";
		var cacheKey = "Detected foreign objects for generated SQL. Obj: #arguments.objectName#. Data: #StructKeyList( arguments.data )#. Fields: #ArrayToList( arguments.selectFields )#. Order by: #arguments.orderBy#. Filter: #IsStruct( filter ) ? StructKeyList( filter ) : filter#. Having: #having#";

		for( var join in extraJoins ) {
			cacheKey &= " ExtraJoins: #( join.joinToTable ?: '' )#.#( join.joinToColumn ?: '' )#";
		}
		for( var extraFilter in extraFilters ) {
			if ( IsArray( extraFilter.extraJoins ?: "" ) ) {
				for( var join in extraFilter.extraJoins ) {
					cacheKey &= "#( join.joinToTable ?: '' )#.#( join.joinToColumn ?: '' )#";
				}
			}
		}

		return hash( _removeDynamicElementsFromForeignObjectsCacheKey( cacheKey ) );
	}

	private string function _removeDynamicElementsFromForeignObjectsCacheKey( required string cacheKey ) {
		var staticCacheKey = arguments.cacheKey;

		staticCacheKey = staticCacheKey.reReplaceNoCase( "[0-9a-f]{32}", "", "all" );
		staticCacheKey = staticCacheKey.reReplaceNoCase( "[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{16}", "", "all" );
		staticCacheKey = staticCacheKey.reReplaceNoCase( "field\s?\(.*?\)", "", "all" );

		return staticCacheKey;
	}

	private boolean function _cacheKeyContainsDynamicElements( required string cacheKey ) {
		if ( ReFindNoCase( "[0-9a-f]{32}\b", arguments.cacheKey ) ){
			return true;
		}
		if ( ReFindNoCase( "[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{16}\b", arguments.cacheKey ) ){
			return true;
		}
		if ( ReFindNoCase( "field\s?\(.*?\)", arguments.cacheKey ) ){
			return true;
		}

		return false;
	}

	private struct function _getSelectDataArgsFromView( required string view ) {
		var args               = _getSelectDataViewService().getViewArgs( arguments.view );
		var arrayAppendFields  = [ "extraFilters", "extraSelectFields", "savedFilters", "extraJoins", "bypassTenants"  ];
		var structAppendFields = [ "tenantIds" ];
		var ignoreFields       = [ "objectName", "filter", "filterParams" ]

		args.extraFilters = args.extraFilters ?: [];
		args.filterParams = args.filterParams ?: {};

		if ( ( IsSimpleValue( arguments.filter ?: "" ) && Len( Trim( arguments.filter ?: "" ) ) || ( IsStruct( arguments.filter ?: "" ) && StructCount( arguments.filter ) ) ) ) {
			args.extraFilters.append( {
				  filter       = arguments.filter
				, filterParams = arguments.filterParams ?: {}
			} );
		} else if ( StructCount( arguments.filterParams ?: {} ) ) {
			StructAppend( args.filterParams, arguments.filterParams );
		}

		for( var field in arguments ) {
			if ( ArrayFindNoCase( ignoreFields, field ) ) {
				continue;
			}

			if ( ArrayFindNoCase( arrayAppendFields, field ) ) {
				args[ field ] = args[ field ] ?: [];
				ArrayAppend( args[ field ], arguments[ field ], true );
			} else if ( ArrayFindNoCase( structAppendFields, field ) ) {
				args[ field ] = args[ field ] ?: {};

				StructAppend( args[ field ], arguments[ field ] );
			} else if ( !IsNull( arguments[ field ] ) ) {
				args[ field ] = arguments[ field ];
			}
		}

		return args;
	}

	private struct function _cleanupPropertyAliases() {
		if ( _getAliasCache().isEmpty() ) {
			return arguments;
		}

		if ( StructKeyExists( arguments, "selectFields" ) ) {
			for( var i=1; i<=arguments.selectFields.len(); i++ ) {
				arguments.selectFields[ i ] = _simpleReplacer( arguments.selectFields[ i ], arguments.objectName, true );
			}
		}

		if ( StructKeyExists( arguments, "filter" ) ) {
			if ( IsSimpleValue( arguments.filter ) ) {
				arguments.filter = _simpleReplacer( arguments.filter, arguments.objectName );
			} else {
				_structKeyReplacer( arguments.filter, arguments.objectName );
			}
		}

		if ( StructKeyExists( arguments, "filterParams" ) ) {
			_structKeyReplacer( arguments.filterParams, arguments.objectName );
		}

		if ( StructKeyExists( arguments, "data" ) ) {
			_structKeyReplacer( arguments.data, arguments.objectName );
		}

		if ( StructKeyExists( arguments, "having" ) ) {
			arguments.having = _simpleReplacer( arguments.having, arguments.objectName );
		}

		if ( StructKeyExists( arguments, "orderBy" ) ) {
			arguments.orderBy = _simpleReplacer( arguments.orderBy, arguments.objectName );
		}

		if ( StructKeyExists( arguments, "groupBy" ) ) {
			arguments.groupBy = _simpleReplacer( arguments.groupBy, arguments.objectName );
		}

		return arguments;
	}

	private any function _findAndReplace( plainString, objectName ) {
		var aliasCache = _getAliasCache();
		if ( Len( aliasCache[ arguments.objectName ][ plainString ] ?: "" ) ) {
			return [ {
				  fullMatch     = plainString
				, replaceWith   = aliasCache[ arguments.objectName ][ plainString ]
				, aliasProperty = plainString
				, realProperty  = aliasCache[ arguments.objectName ][ plainString ]
			} ];
		}

		var useCache = !_cacheKeyContainsDynamicElements( arguments.plainString );
		if ( useCache ) {
			var cache    = _getSimpleLocalCache();
			var cacheKey = "_cleanupProperyAliasesFAndR#arguments.objectName##arguments.plainString#";

			if ( StructKeyExists( cache, cachekey ) ) {
				return cache[ cacheKey ];
			}
		}

		var aliasRegex  = _getAlaisedAliasRegex();
		var matches = _reSearch( aliasRegex, plainString );
		var results = [];

		if ( StructKeyExists( matches, "$1" ) ) {
			for( var i=1; i<=matches.$1.len(); i++ ) {
				var fullMatch   = matches.$1[i] & matches.$2[i] & matches.$6[i] & "." & matches.$7[i] & matches.$8[i] & matches.$9[i];
				var objPath     = matches.$2[i];
				var propName    = matches.$8[i];
				var objFromPath = _resolveObjectNameFromColumnJoinSyntax( arguments.objectName, objPath );

				if ( Len( aliasCache[ objFromPath ][ propName ] ?: "" ) ) {
					results.append( {
						  fullMatch     = fullMatch
						, replaceWith   = matches.$1[i] & matches.$2[i] & matches.$6[i] & "." & matches.$7[i] & aliasCache[ objFromPath ][ propName ] & matches.$9[i]
						, aliasProperty = aliasCache[ objFromPath ][ propName ]
						, realProperty  = propName
					} );
				}
			}
		}

		if ( useCache ) {
			cache[ cacheKey ] = results;
		}

		return results;
	};


	private any function _structKeyReplacer( theStruct, objectName ){
		for( var key in theStruct ) {
			var fAndRResult = _findAndReplace( key, arguments.objectName );
			for( var r in fAndRResult ){
				var newKey = key.replace( r.fullMatch, r.replaceWith, "all" );
				theStruct[ newKey ] = theStruct[ key ];
				theStruct.delete( key );
			}
		}
	}

	private any function _simpleReplacer( plainString, objectName, addAsAlias=false ) {
		var useCache = !_cacheKeyContainsDynamicElements( arguments.plainString );

		if ( useCache ) {
			var cache = _getSimpleLocalCache();
			var cacheKey = "_cleanupProperyAliasesReplacer#arguments.objectName##arguments.plainString##arguments.addAsAlias#";

			if ( StructKeyExists( cache, cacheKey ) ) {
				return cache[ cacheKey ];
			}
		}

		var replaced    = plainString;
		var fAndRResult = _findAndReplace( plainString, arguments.objectName );

		for( var r in fAndRResult ){
			replaced = replaced.replace( r.fullMatch, r.replaceWith, "all" );
		}
		if ( addAsAlias && fAndRResult.len() && !plainString.findNoCase( " as " ) ) {
			replaced &= " as " & fAndRResult[1].aliasProperty;
		}

		if ( useCache ) {
			cache[ cacheKey ] = replaced;
		}

		return replaced;
	}

	private array function _getJoinsFromJoinTargets(
		  required string  objectName
		, required array   joinTargets
		, required string  forceJoins
		, required boolean fromVersionTable
	) {
		if ( !ArrayLen( arguments.joinTargets ) ) {
			return [];
		}

		var joinsCache    = _getSimpleLocalCache();
		var joinsCacheKey = "SQL Joins for #arguments.objectName# with join targets: #ArrayToList( arguments.joinTargets )#. From version table: #arguments.fromVersionTable#. Forcing joins: [#arguments.forceJoins#]."

		if ( !StructKeyExists( joinsCache, joinsCacheKey ) ) {
			joinsCache[ joinsCacheKey ] = _getRelationshipGuidance().calculateJoins( objectName = arguments.objectName, joinTargets = joinTargets, forceJoins = arguments.forceJoins );
		}

		return joinsCache[ joinsCacheKey ];

	}

	private array function _convertObjectJoinsToTableJoins(
		  required array  joins
		,          array  extraJoins   = []
		,          array  extraFilters = []
		,          array  savedFilters = []
		,          struct preparedFilter = {}
	) {
		var tableJoins = [];
		var objJoin    = "";
		var objects    = _getObjects();
		var tableJoin  = "";
		var join       = {};

		for( objJoin in arguments.joins ){
			if ( Len( Trim( objJoin.subquery ?: "" ) ) || Len( Trim( objJoin.selectDataView ?: "" ) ) ) {
				join = StructCopy( objJoin );

				if ( Len( Trim( objJoin.selectDataView ?: "" ) ) ) {
					var sqlAndParams = _getSelectDataViewService().getSqlAndParams( objJoin.selectDataView );

					join.subQuery       = sqlAndParams.sql;
					join.subQueryParams = sqlAndParams.params;
				}

				if ( IsArray( join.subQueryParams ?: "" ) ) {
					arguments.preparedFilter.params = arguments.preparedFilter.params ?: [];
					arguments.preparedFilter.params.append( join.subQueryParams, true );
				}
			} else {
				join = {
					  tableName    = objects[ objJoin.joinToObject ].meta.tableName
					, tableAlias   = objJoin.tableAlias ?: objJoin.joinToObject
					, tableColumn  = objJoin.joinToProperty
					, joinToTable  = objJoin.joinFromAlias ?: objJoin.joinFromObject
					, joinToColumn = objJoin.joinFromProperty
					, type         = objJoin.type
				};

				if ( IsBoolean( objJoin.addVersionClause ?: "" ) && objJoin.addVersionClause ) {
					join.additionalClauses = "#join.tableAlias#._version_number = #join.joinToTable#._version_number";
				}
			}

			tableJoins.append( join );
		}

		tableJoins.append( arguments.extraJoins, true );

		for( var savedFilter in arguments.savedFilters ){
			savedFilter = _getFilterService().getFilter( savedFilter );

			if ( IsArray( savedFilter.extraJoins ?: "" ) ) {
				tableJoins.append( savedFilter.extraJoins, true );
			}
		}

		for( var extraFilter in arguments.extraFilters ){
			if ( IsArray( extraFilter.extraJoins ?: "" ) ) {
				tableJoins.append( extraFilter.extraJoins, true );
			}
		}

		var interceptArguments = arguments;
		interceptArguments.tableJoins = tableJoins;
		_announceInterception( "postPrepareTableJoins", interceptArguments );

		return interceptArguments.tableJoins;
	}

	private query function _selectFromVersionTables(
		  required string  objectName
		, required string  originalTableName
		, required array   joins
		, required array   selectFields
		, required numeric specificVersion
		, required boolean allowDraftVersions
		, required any     filter
		, required array   params
		, required string  orderBy
		, required string  groupBy
		, required numeric maxRows
		, required numeric startRow
		,          boolean distinct = false
	) {
		var adapter              = getDbAdapterForObject( arguments.objectName );
		var versionObj           = _getObject( getVersionObjectName( arguments.objectName ) ).meta;
		var versionTableName     = versionObj.tableName;
		var compiledSelectFields = Duplicate( arguments.selectFields );
		var compiledFilter       = Duplicate( arguments.filter );
		var sql                  = "";
		var versionFilter        = "";
		var args                 = {};
		var alteredJoins         = _alterJoinsToUseVersionTables(
			  argumentCollection = arguments
			, versionTableName   = versionTableName
			, preparedFilter     = { filter=arguments.filter, params=arguments.params }
		);

		if ( not ArrayLen( arguments.selectFields ) ) {
			compiledSelectFields = _dbFieldListToSelectFieldsArray( versionObj.dbFieldList, arguments.objectName, adapter );
		}

		if ( arguments.specificVersion ) {
			versionFilter = "#arguments.objectName#._version_number = :#arguments.objectName#._version_number";
			params.append( { name="#arguments.objectName#___version_number", value=arguments.specificVersion, type="cf_sql_int" } );

			if ( !arguments.allowDraftVersions ) {
				versionFilter &= " and ( #arguments.objectName#._version_is_draft is null or #arguments.objectName#._version_is_draft = :#arguments.objectName#._version_is_draft )";
				params.append( { name="#arguments.objectName#___version_is_draft", value=false, type="cf_sql_bit" } );
			}

		} else {
			var latestVersionField = arguments.allowDraftVersions ? "_version_is_latest_draft" : "_version_is_latest";
			versionFilter = "#arguments.objectName#.#latestVersionField# = :#arguments.objectName#.#latestVersionField#";
			params.append( { name="#arguments.objectName#__#latestVersionField#", value=true, type="cf_sql_boolean" } );
		}

		compiledFilter = mergeFilters( compiledFilter, versionFilter, adapter, arguments.objectName );

		var args = Duplicate( arguments );
		args.append( {
			  tableName     = versionTableName
			, tableAlias    = arguments.objectName
			, selectColumns = compiledSelectFields
			, filter        = compiledFilter
			, joins         = alteredJoins
			, orderBy       = arguments.orderBy
			, groupBy       = arguments.groupBy
			, maxRows       = arguments.maxRows
			, startRow      = arguments.startRow
			, distinct      = arguments.distinct
		} );
		_announceInterception( "postPrepareVersionSelect", args );

		sql = adapter.getSelectSql( argumentCollection=args );

		return _runSql( sql=sql, dsn=versionObj.dsn, params=arguments.params );
	}

	private array function _alterJoinsToUseVersionTables(
		  required array  joins
		, required string originalTableName
		, required string versionTableName
		, required string objectName
		, required struct preparedFilter
	) {
		var manyToManyObjects = {};
		var isPageType        = isPageType( arguments.objectName );
		var pageIsVersioned   = objectExists( "page" ) && objectIsVersioned( "page" );

		for( var join in arguments.joins ){
			if ( Len( Trim( join.manyToManyProperty ?: "" ) ) ) {
				manyToManyObjects[ join.joinToObject ] = 1;
			}

			if ( isPageType && pageIsVersioned && join.joinFromObject == arguments.objectName && join.joinToObject == "page" ) {
				join.joinToObject     = getVersionObjectName( "page" );
				join.addVersionClause = true;
				join.tableAlias       = "page";
			}
		}

		for( var obj in manyToManyObjects ){
			if ( !objectIsVersioned( obj ) ) {
				StructDelete( manyToManyObjects, obj );
			}
		}

		if ( manyToManyObjects.len() ) {
			for( var join in arguments.joins ){
				if ( StructKeyExists( manyToManyObjects, join.joinFromObject ) ) {
					join.joinFromObject = getVersionObjectName( join.joinFromObject );
				}
				if ( StructKeyExists( manyToManyObjects, join.joinToObject ) ) {
					join.tableAlias = join.joinToObject;
					join.joinToObject = getVersionObjectName( join.joinToObject );
					join.addVersionClause = true;
				}
			}
		}

		return _convertObjectJoinsToTableJoins( argumentCollection=arguments, joins=arguments.joins );
	}

	private array function _dbFieldListToSelectFieldsArray( required string fieldList, required string tableAlias, required any dbAdapter ) {
		var fieldArray   = ListToArray( arguments.fieldList );
		var convertedArray = [];
		var escapedAlias = dbAdapter.escapeEntity( arguments.tableAlias );

		for( var i=1; i <= fieldArray.len(); i++ ){
			var fieldName = escapedAlias & "." & dbAdapter.escapeEntity( fieldArray[i] );
			if( !arrayFind( convertedArray, fieldName ) ){
				convertedArray.append( fieldName );
			}
			var prop = getObjectProperty( tableAlias, fieldArray[i] );
			for( var alias in ( prop.aliases ?: "" ).listToArray() ) {
				var aliasName = fieldName & " as " & dbAdapter.escapeEntity( alias );
				if( !arrayFind( convertedArray, aliasName ) ){
					convertedArray.append( aliasName );
				}
			}
		}

		return convertedArray;
	}

	private string function _generateNewIdWhenNecessary( required string generator ) {
		switch( arguments.generator ){
			case "UUID": return CreateUUId();
		}

		return "";
	}

	private array function _arrayMerge( required array arrayA, required array arrayB ) {
		var newArray = Duplicate( arguments.arrayA );
		var node     = "";

		for( node in arguments.arrayB ){
			ArrayAppend( newArray, node );
		}

		return newArray;
	}

	private string function _getAlaisedFieldRegex() {
		var entityPattern = "[a-zA-Z_][a-zA-Z0-9_]*";

		return "(^|\s|,|\(|\)|`|\[)((#entityPattern#)(\$(#entityPattern#))*)[`\]]?\.[`\[]?(#entityPattern#)(\s|$|\)|,|`|\])";
	}

	private struct function _getEntityNames() {
		if ( !StructKeyExists( this, "_entityNames" ) ) {
			this._entityNames = {};

			for( var objName in _getObjects() ){
				this._entityNames[ objName ] = 1;

				for( var propertyName in getObjectProperties( objName ) ) {
					this._entityNames[ propertyName ] = 1;
				}
			}
		}

		return this._entityNames;
	}

	private string function _getAlaisedAliasRegex() {
		if ( !StructKeyExists( this, "_aliasedAliasRegex" ) ) {
			var objects  = _getObjects();
			var entities = {};
			var aliasEntitiesOnly = {};

			for( var objName in objects ){
				entities[ objName ] = 1;

				for( var propertyName in objects[ objName ].meta.properties ) {
					var prop = objects[ objName ].meta.properties[ propertyName ];

					for( var alias in ( prop.aliases ?: "" ).listToArray() ) {
						entities[ alias ] = 1;
						aliasEntitiesOnly[ alias ] = 1;
					}
				}
			}
			entities = StructKeyList( entities, "|" );
			aliasEntitiesOnly = StructKeyList( aliasEntitiesOnly, "|" );

			_aliasedAliasRegex = "(^|\s|,|\(|\)|`|\[)((#entities#)(\$(#entities#))*)([`\]])?\.([`\[])?(#aliasEntitiesOnly#)(\s|$|\)|,|`|\])";
		}

		return _aliasedAliasRegex;
	}

	private struct function _reSearch( required string regex, required string text ) {
		var final 	= StructNew();
		var pos		= 1;
		var result	= ReFindNoCase( arguments.regex, arguments.text, pos, true );
		var i		= 0;

		while( ArrayLen(result.pos) GT 1 ) {
			for(i=2; i LTE ArrayLen(result.pos); i++){
				if(not StructKeyExists(final, '$#i-1#')){
					final['$#i-1#'] = ArrayNew(1);
				}

				if ( result.pos[i] ) {
					ArrayAppend( final['$#i-1#'], Mid( arguments.text, result.pos[i], result.len[i] ) );
				} else {
					ArrayAppend( final['$#i-1#'], "" );
				}
			}
			pos = result.pos[2] + 1;
			result	= ReFindNoCase( arguments.regex, arguments.text, pos, true );
		} ;

		return final;
	}

	private boolean function _isEmptyFilter( required any filter ) {
		if ( IsStruct( arguments.filter ) ) {
			return StructIsEmpty( arguments.filter );
		}

		if ( IsSimpleValue( arguments.filter ) ) {
			return not Len( Trim( arguments.filter ) );
		}

		return true;
	}

	private string function _parseOrderBy( required string orderBy, required string objectName, required any dbAdapter ) {
		var items   = arguments.orderBy.listToArray();
		var rebuilt = [];

		for( var item in items ) {
			var propertyName = expandFormulaFields( objectName=arguments.objectName, expression=Trim( ListFirst( item, " " ) ), dbAdapter=arguments.dbAdapter, includeAlias=false );
			var direction    = ListLen( item, " " ) > 1 ? " " & ListRest( item, " ") : "";
			var aliased      = _autoPrefixBareProperty( arguments.objectName, propertyName, arguments.dbAdapter );

			if ( propertyName != aliased ) {
				item = aliased & direction;
			} else {
				item = propertyName & direction;
			}

			rebuilt.append( Trim( item ) );
		}

		return rebuilt.toList( ", " );
	}

	private string function _resolveObjectNameFromColumnJoinSyntax( required string startObject, required string joinSyntax ) {
		variables._relationshipPathCalcCache = variables._relationshipPathCalcCache ?: {};
		var cacheKey = arguments.startObject & arguments.joinSyntax;

		if ( !StructKeyExists( _relationshipPathCalcCache, cacheKey ) ) {
			_relationshipPathCalcCache[ cacheKey ] = _getRelationshipGuidance().resolveRelationshipPathToTargetObject(
				  sourceObject     = arguments.startObject
				, relationshipPath = arguments.joinSyntax
			);
		}

		return _relationshipPathCalcCache[ cacheKey ];
	}

	private array function _expandSavedFilters( required array savedFilters ) {
		var expanded      = [];
		var filterService = _getFilterService();

		for( var savedFilter in arguments.savedFilters ){
			savedFilter = filterService.getFilter( savedFilter );

			expanded.append({
				  filter       = savedFilter.filter       ?: {}
				, filterParams = savedFilter.filterParams ?: {}
				, having       = savedFilter.having       ?: ""
			});
		}

		return expanded;
	}

	private struct function _addDefaultFilters( required struct args ){
		var defaultFilters = ListToArray( getObjectAttribute( args.objectName, "defaultFilters", "" ) );

		if( ArrayLen( defaultFilters ) ){
			var ignoreFilters = args.ignoreDefaultFilters ?: [];
			for( var filter in ignoreFilters ) {
				ArrayDelete( defaultFilters, filter );
			}
		}

		if ( ArrayLen( defaultFilters ) ) {
			args.savedFilters = args.savedFilters ?: [];
			ArrayAppend( args.savedFilters, defaultFilters, true );
		}

		return args;
	}

	private struct function _prepareFilter(
		  required string objectName
		, required any    filter
		, required struct filterParams
		, required array  extraFilters
		, required array  savedFilters
		, required any    adapter
		, required struct columnDefinitions
		,          string having = ""
		,          string id
	) {
		_announceInterception( "prePrepareObjectFilter", arguments );

		var idField = getIdField( arguments.objectName );
		var result = {
			  filter       = StructKeyExists( arguments, "id" ) ? { "#idField#" = arguments.id } : Duplicate( arguments.filter )
			, filterParams = Duplicate( arguments.filterParams )
			, having       = Duplicate( arguments.having )
		};
		if ( IsStruct( result.filter ) && ( arguments.extraFilters.len() || arguments.savedFilters.len() ) ) {
			result.filterParams.append( Duplicate( result.filter ) );
		}

		for( var extraFilter in arguments.extraFilters ){
			extraFilter.filter       = extraFilter.filter       ?: {};
			extraFilter.filterParams = extraFilter.filterParams ?: {};
			extraFilter.having       = extraFilter.having       ?: "";

			extraFilter = _cleanupPropertyAliases( argumentCollection=extraFilter, objectName=arguments.objectName );
			extraFilter.delete( "objectName" );

			result.filterParams.append( extraFilter.filterParams ?: {} );
			if ( IsStruct( extraFilter.filter ) ) {
				result.filterParams.append( extraFilter.filter );
			}

			result.filter = mergeFilters(
				  filter1    = result.filter
				, filter2    = extraFilter.filter
				, dbAdapter  = arguments.adapter
				, tableAlias = arguments.objectName
			);
			if ( Len( Trim( extraFilter.having ) ) ) {
				result.having = mergeFilters(
					  filter1    = result.having
					, filter2    = extraFilter.having
					, dbAdapter  = arguments.adapter
					, tableAlias = arguments.objectName
				);
			}
		}

		if ( IsStruct( result.filter ) ) {
			for( var key in result.filter ) {
				var aliasedKey = _autoPrefixBareProperty( objectName=arguments.objectName, propertyName=key, dbAdapter=arguments.adapter, escapeEntities=false );
				if ( aliasedKey != key ) {
					result.filter[ aliasedKey ] = result.filter[ key ];
					result.filter.delete( key );
				}
			}

			result.params = _convertDataToQueryParams(
				  objectName        = arguments.objectName
				, columnDefinitions = arguments.columnDefinitions
				, data              = result.filter
				, dbAdapter         = adapter
			);
		}

		if ( !IsStruct( result.filter ) || result.having.len() ) {
			for( var key in result.filterParams ) {
				var aliasedKey = _autoPrefixBareProperty( objectName=arguments.objectName, propertyName=key, dbAdapter=arguments.adapter, escapeEntities=false );
				if ( aliasedKey != key ) {
					result.filterParams[ aliasedKey ] = result.filterParams[ key ];
					result.filterParams.delete( key );
					if ( IsSimpleValue( result.filter ) ) {
						result.filter = result.filter.reReplaceNoCase( ":#key#(\b)", ":#aliasedKey#\1", "all" );
					}
					result.having = result.having.reReplaceNoCase( ":#key#(\b)", ":#aliasedKey#\1", "all" );
				}
			}

			var objOrPropRegex = "[a-z_\-][a-z0-9_\-]*";
			if ( IsSimpleValue( result.filter ) ) {
				result.filter = ReReplaceNoCase( result.filter, "(:#objOrPropRegex#)[\.\$](#objOrPropRegex#)", "\1__\2", "all" );
			}
			result.having = ReReplaceNoCase( result.having, "(:#objOrPropRegex#)[\.\$](#objOrPropRegex#)", "\1__\2", "all" );
		}
		result.params = result.params ?: [];
		if ( result.filterParams.count() ) {
			result.params.append( _convertUserFilterParamsToQueryParams(
				  columnDefinitions = arguments.columnDefinitions
				, params            = result.filterParams
				, dbAdapter         = adapter
				, objectName        = arguments.objectName
			), true );
		}

		var interceptData = arguments;
		    interceptData.result = result;

		_announceInterception( "postPrepareObjectFilter", interceptData );
		return result;
	}

	private struct function _addDefaultValuesToDataSet( required string objectName, required struct data ) {
		var props   = getObjectProperties( arguments.objectName );
		var newData = Duplicate( arguments.data );

		for( var propName in props ){
			if ( !StructKeyExists( arguments.data, propName ) && Len( Trim( props[ propName ].default ?: "" ) ) ) {
				var default = props[ propName ].default;
				switch( ListFirst( default, ":" ) ) {
					case "cfml":
						newData[ propName ] = Evaluate( ListRest( default, ":" ) );
					break;
					case "closure":
						var func = Evaluate( ListRest( default, ":" ) );
						newData[ propName ] = func( arguments.data );
					break;
					case "method":
						var obj = getObject( arguments.objectName );

						newData[ propName ] = obj[ ListRest( default, ":" ) ]( arguments.data );
					break;
					default:
						newData[ propName ] = default;
				}
			}
		}

		return newData;
	}

	private struct function _addGeneratedValues( required string operation, required string objectName, required struct data, string id="" ) {
		var obj       = getObject( arguments.objectName );
		var props     = getObjectProperties( arguments.objectName );
		var newData   = Duplicate( arguments.data );
		var generated = {};
		var genOps    = arguments.operation == "insert" ? [ "insert", "always" ] : [ "always" ];

		if ( isSimpleValue( obj ) ) {
			return generated;
		}

		for( var propName in props ){
			var prop = props[ propName ];

			if ( genOps.findNoCase( prop.generate ?: "" ) ) {
				if ( arguments.operation == "insert" && Len( Trim( arguments.data[ propName ] ?: "" ) ) ) {
					continue;
				}

				var generatedValue = _generateValue( arguments.objectName, arguments.id, prop.generator, newData, prop );
				if ( !IsNull( local.generatedValue ) ) {
					generated[ propName ] = newData[ propName ] = generatedValue;
				}
			}
		}

		return generated;
	}

	private any function _generateValue( required string objectName, required string id, required string generator, required struct data, required struct prop ) {
		switch( ListFirst( arguments.generator, ":" ) ) {
			case "UUID":
				return CreateUUId();
			break;
			case "timestamp":
				return DateFormat( Now(), "yyyy-mm-dd" ) & " " & TimeFormat( Now(), "HH:mm:ss" );
			break;
			case "method":
				var obj = getObject( arguments.objectName );

				return obj[ ListRest( arguments.generator, ":" ) ]( arguments.data );
			break;
			case "hash":
				if ( Len( Trim( prop.generateFrom ?: "" ) ) ) {
					var valueToHash = "";
					for( var field in ListToArray( prop.generateFrom ) ) {
						if ( StructKeyExists( arguments.data, field ) ) {
							valueToHash &= arguments.data[ field ];
						} else {
							return;
						}
					}

					return Hash( valueToHash );
				}
			break;
			case "slug":
				var generateFrom = prop.generateFrom ?: getLabelField( arguments.objectName );
				var idField      = getIdField( arguments.objectName );

				if ( len( arguments.data[ prop.name ] ?: "" ) || !StructKeyExists( arguments.data, generateFrom ) ) {
					return;
				}

				var slug         = slugify( arguments.data[ generateFrom ] );
				var filter       = "slug = :slug";
				var filterParams = { slug=slug };
				var increment    = 0;

				if ( len( arguments.id ) ) {
					filter &= " and id != :id";
					filterParams.id = arguments.id;
				}

				while( dataExists( objectName=arguments.objectName, filter=filter, filterParams=filterParams ) ) {
					if ( increment ) {
						slug = ReReplace( slug, "\-[0-9]+$", "" );
					}
					slug &= "-" & ++increment;
					filterParams.slug = slug;
				}

				return slug;
			break;
		}

		return;
	}

	private struct function _getDraftExclusionFilter( required string objectName ) {
		return {
			  filter       = "#arguments.objectName#._version_is_draft is null or #arguments.objectName#._version_is_draft = :#arguments.objectName#._version_is_draft"
			, filterparams = { "#arguments.objectName#._version_is_draft" = false }
		};
	}

	private string function _autoPrefixBareProperty(
		  required string  objectName
		, required string  propertyName
		, required any     dbAdapter
		,          string  alias          = arguments.objectName
		,          boolean escapeEntities = true
	) {
		var objMeta       = _getObject( arguments.objectName ).meta;
		var barePropRegex = "^(" & objMeta.dbFieldList.replace( ",", "|", "all" ) & ")$";
		var aliasRegex    = "^([^\s]+)(\s+as\s+.+)$";
		var propName      = arguments.propertyName;
		var propAlias     = "";

		if ( propName.reFind( aliasRegex ) ) {
			propName  = arguments.propertyName.reReplace( aliasRegex, "\1" );
			propAlias = arguments.propertyName.reReplace( aliasRegex, "\2" );
		}

		if ( propName.reFindNoCase( barePropRegex ) ) {
			if ( escapeEntities ) {
				return dbAdapter.escapeEntity( arguments.alias ) & "." & dbAdapter.escapeEntity( propName ) & propAlias;
			}
			return arguments.alias & "." & arguments.propertyName;
		}

		return arguments.propertyName;
	}

	private boolean function _isDraft( array extraFilters=[] ) {
		var draftCheckFilters = Duplicate( arguments.extraFilters );

		draftCheckFilters.append( { filter={ _version_is_draft=true } } );

		return dataExists( argumentCollection=arguments, extraFilters=draftCheckFilters );
	}

	private string function _autoCalculateGroupBy( required array selectFields ) {
		var groupBy            = "";
		var hasAggregateFields = false;
		var aggregateRegex     = "(group_concat|avg|corr|count|count|covar_pop|covar_samp|cume_dist|dense_rank|min|max|percent_rank|percentile_cont|percentile_disc|rank|regr_avgx|regr_avgy|regr_count|regr_intercept|regr_r2|regr_slope|regr_sxx|regr_sxy|regr_syy|stddev_pop|stddev_samp|sum|var_pop|var_sam)\s?\(";


		for( var field in selectFields ) {
			var isAggregate = field.reFindNoCase( aggregateRegex );
			hasAggregateFields = hasAggregateFields || isAggregate;

			if ( !isAggregate ) {
				groupBy = groupBy.listAppend( field.reReplace( "^(.*?) as .*$", "\1" ) );
			}
		}

		return hasAggregateFields ? groupBy : "";
	}

	private boolean function _getUseCacheDefault( required string objectName ) {
		try {
			return request[ "_defaultUseCache#arguments.objectName#" ];
		} catch( any e ) {
			request[ "_defaultUseCache#arguments.objectName#" ] = _objectUsesCaching( arguments.objectName ) && $getRequestContext().getUseQueryCache();
		}

		return request[ "_defaultUseCache#arguments.objectName#" ];
	}

	private boolean function _getDefaultAllowDraftVersions() {
		try {
			return request._defaultAllowDraftVersions;
		} catch( any e ) {
			request._defaultAllowDraftVersions = $getRequestContext().showNonLiveContent();
		}

		return request._defaultAllowDraftVersions;
	}

	private boolean function _objectUsesCaching( required string objectName ) {
		var objectUsesCaching = getObjectAttribute( arguments.objectName, "useCache", true );

		return !IsBoolean( objectUsesCaching ) || objectUsesCaching;
	}

	private numeric function _seekStartPosWithBinarySort( required string prefix, required array target ) {
		var prefixLen = Len( prefix );
		var left      = 1;
		var right     = ArrayLen( target );
		var pos       = 0;

		// prefix is less than start OR greater than end (will not be found in whole array)
		if ( Compare( prefix, Left( target[ right ], prefixLen ) ) == 1 || Compare( prefix, Left( target[ 1 ], prefixLen ) ) == -1 ) {
			return 0;
		}

		while( left <= right ) {
			pos = Int( ( left+right ) / 2 );
			var comparison = Compare( Left( target[ pos ], prefixLen ), prefix );
			if ( comparison == -1 ) {
				left = pos+1;
			} else if ( comparison == 1 ) {
				right = pos-1;
			} else {
				if ( pos == 1 || Compare( Left( target[ pos-1 ], prefixLen ), prefix ) != 0 ) {
					return pos;
				}
				right = pos-1;
			}
		}

		return 0;
	}

	private any function _setupObjectQueryCache( required any defaultQueryCache, required string objectName ) {
		var cachebox      = $getColdbox().getCachebox();
		var obj           = _getObject( arguments.objectName );
		var defaultConfig = cachebox.getConfig().getCache( "defaultQueryCache" );
		var newConfig     = {
			  name       = "presideQueryCache_#arguments.objectName#"
			, provider   = ( obj.meta.cacheProvider ?: defaultConfig.provider )
			, properties = StructCopy( defaultConfig.properties )
		};

		for( var attrib in obj.meta ) {
			if ( attrib.reFindNoCase( "^cache" ) ) {
				newConfig.properties[ attrib.reReplaceNoCase( "^cache", "" ) ] = obj.meta[ attrib ];
			}
		}

		try {
			cachebox.createCache( argumentCollection=newConfig );
		} catch ( "CacheFactory.CacheExistsException" e ) {}

		return cachebox.getCache( newConfig.name );
	}

	private void function _clearRelatedCachesWithQueryCachePerObject(
		  required string  objectName
		,          array   relatedObjectsToClear   = []
	) {
		_getDefaultQueryCache( arguments.objectName ).clearAll();

		for( var relatedObjectName in relatedObjectsToClear ) {
			_getDefaultQueryCache( relatedObjectName ).clearAll();
		}
	}

	private void function _clearAllQueryCaches() {
		_getDefaultQueryCache().clearAll();

		if ( $isFeatureEnabled( "queryCachePerObject" ) ) {
			var caches = variables._objectQueryCaches ?: {};
			for( var cacheName in caches ) {
				caches[ cacheName ].clearAll();
			}
		}
	}


// SIMPLE PRIVATE PROXIES
	private any function _getAdapter() {
		return _getAdapterFactory().getAdapter( argumentCollection = arguments );
	}

	private any function _runSql() {
		return _getSqlRunner().runSql( argumentCollection = arguments );
	}

	private any function _announceInterception( required string state, struct interceptData={} ) {
		_getInterceptorService().processState( argumentCollection=arguments );

		return interceptData.interceptorResult ?: {};
	}

// GETTERS AND SETTERS
	private array function _getObjectDirectories() {
		return _objectDirectories;
	}
	private void function _setObjectDirectories( required array objectDirectories ) {
		_objectDirectories = arguments.objectDirectories;
	}

	private any function _getObjectReader() {
		return _objectReader;
	}
	private void function _setObjectReader( required any objectReader ) {
		_objectReader = arguments.objectReader;
	}

	private any function _getSqlSchemaSynchronizer() {
		return _sqlSchemaSynchronizer;
	}
	private void function _setSqlSchemaSynchronizer( required any sqlSchemaSynchronizer ) {
		_sqlSchemaSynchronizer = arguments.sqlSchemaSynchronizer;
	}

	private any function _getAdapterFactory() {
		return _adapterFactory;
	}
	private void function _setAdapterFactory( required any adapterFactory ) {
		_adapterFactory = arguments.adapterFactory;
	}

	private any function _getSqlRunner() {
		return _sqlRunner;
	}
	private void function _setSqlRunner( required any sqlRunner ) {
		_sqlRunner = arguments.sqlRunner;
	}

	private any function _getRelationshipGuidance() {
		return _relationshipGuidance;
	}
	private void function _setRelationshipGuidance( required any relationshipGuidance ) {
		_relationshipGuidance = arguments.relationshipGuidance;
	}

	private any function _getVersioningService() {
		return _versioningService;
	}
	private void function _setVersioningService( required any versioningService ) {
		_versioningService = arguments.versioningService;
	}

	private any function _getLabelRendererService() {
		return _labelRendererService;
	}
	private void function _setLabelRendererService( required any labelRendererService ) {
		_labelRendererService = arguments.labelRendererService;
	}

	private any function _getPresideObjectDecorator() {
		return _presideObjectDecorator;
	}
	private void function _setPresideObjectDecorator( required any presideObjectDecorator ) {
		_presideObjectDecorator = arguments.presideObjectDecorator;
	}

	private any function _getFilterService() {
		return _filterService;
	}
	private void function _setFilterService( required any filterService ) {
		_filterService = arguments.filterService;
	}

	private any function _getSimpleLocalCache() {
		return _cache;
	}

	private void function _setSimpleLocalCache( required any cache ) {
		_cache = arguments.cache;
	}

	private any function _getDefaultQueryCache( string objectName="" ) {
		if ( Len( Trim( arguments.objectName ) ) && $isFeatureEnabled( "queryCachePerObject" ) ) {
			if ( !IsDefined( "variables._objectQueryCaches.#arguments.objectName#" ) ) {
				variables._objectQueryCaches = variables._objectQueryCaches ?: {};
				variables._objectQueryCaches[ arguments.objectName ] = _setupObjectQueryCache( _defaultQueryCache, arguments.objectName );
			}

			return variables._objectQueryCaches[ arguments.objectName ];
		}
		return _defaultQueryCache;
	}
	private void function _setDefaultQueryCache( required any defaultQueryCache ) {
		_defaultQueryCache = arguments.defaultQueryCache;
	}

	private any function _getInterceptorService() {
		return _interceptorService;
	}
	private void function _setInterceptorService( required any IiterceptorService ) {
		_interceptorService = arguments.IiterceptorService;
	}

	private string function _getThrowOnLongTableName() {
		return _throwOnLongTableName;
	}
	private void function _setThrowOnLongTableName( required string throwOnLongTableName ) {
		_throwOnLongTableName = arguments.throwOnLongTableName;
	}

	private struct function _getObjects() {
		return _objects;
	}
	private void function _setObjects( required struct objects ) {
		_objects = arguments.objects;
	}

	private array function _getDsns() {
		return _dsns;
	}
	private void function _setDsns( required array dsns ) {
		_dsns = arguments.dsns;
	}

	private string function _getInstanceId() {
		return _instanceId;
	}
	private void function _setInstanceId( required string instanceId ) {
		_instanceId = arguments.instanceId;
	}

	private struct function _getAliasCache() {
		return _aliasCache;
	}
	private void function _setAliasCache( required struct aliasCache ) {
		_aliasCache = arguments.aliasCache;
	}

	private struct function _getCacheMap() {
		return _cacheMap;
	}
	private void function _setCacheMap( required struct cacheMap ) {
		_cacheMap = arguments.cacheMap;
	}

	private any function _getSelectDataViewService() {
	    return _selectDataViewService;
	}
	private void function _setSelectDataViewService( required any selectDataViewService ) {
	    _selectDataViewService = arguments.selectDataViewService;
	}
}