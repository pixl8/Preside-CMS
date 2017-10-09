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
	 * @cache.inject                  cachebox:PresideSystemCache
	 * @defaultQueryCache.inject      cachebox:DefaultQueryCache
	 * @coldboxController.inject      coldbox
	 * @interceptorService.inject     coldbox:InterceptorService
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
		, required any     cache
		, required any     defaultQueryCache
		, required any     coldboxController
		, required any     interceptorService
		,          boolean reloadDb = true
	) {
		_setObjectDirectories( arguments.objectDirectories );
		_setObjectReader( arguments.objectReader );
		_setSqlSchemaSynchronizer( arguments.sqlSchemaSynchronizer );
		_setAdapterFactory( arguments.adapterFactory );
		_setSqlRunner( arguments.sqlRunner );
		_setRelationshipGuidance( arguments.relationshipGuidance );
		_setPresideObjectDecorator( arguments.presideObjectDecorator );
		_setFilterService( arguments.filterService );
		_setCache( arguments.cache );
		_setDefaultQueryCache( arguments.defaultQueryCache );
		_setVersioningService( arguments.versioningService );
		_setLabelRendererService( arguments.labelRendererService );
		_setCacheMaps( {} );
		_setInterceptorService( arguments.interceptorService );
		_setInstanceId( CreateObject('java','java.lang.System').identityHashCode( this ) );

		_loadObjects();

		if ( arguments.reloadDb ) {
			dbSync();
		}

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
	 * @objectName.hint          Name of the object from which to select data
	 * @id.hint                  ID of a record to select
	 * @selectFields.hint        Array of field names to select. Can include relationships, e.g. ['tags.label as tag']
	 * @filter.hint              Filter the records returned, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`
	 * @filterParams.hint        Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`
	 * @extraFilters.hint        An array of extra sets of filters. Each array should contain a structure with :code:`filter` and optional `code:`filterParams` keys.
	 * @orderBy.hint             Plain SQL order by string
	 * @groupBy.hint             Plain SQL group by string
	 * @autoGroupBy.hint         Whether or not to try to automatically calculate group by fields for the query
	 * @having.hint              Plain SQL HAVING clause, can contain params that should be present in `filterParams` argument
	 * @maxRows.hint             Maximum number of rows to select
	 * @startRow.hint            Offset the recordset when using maxRows
	 * @useCache.hint            Whether or not to automatically cache the result internally
	 * @fromVersionTable.hint    Whether or not to select the data from the version history table for the object
	 * @specificVersion.hint     Can be used to select a specific version when selecting from the version table
	 * @allowDraftVersions.hint  Choose whether or not to allow selecting from draft records and/or versions
	 * @forceJoins.hint          Can be set to "inner" / "left" to force *all* joins in the query to a particular join type
	 * @extraJoins.hint          An array of explicit joins to add to the query (can define subquery joins this way)
	 * @recordCountOnly.hint     If set to true, the method will just return the number of records that the select statement would return
	 * @getSqlAndParamsOnly.hint If set to true, the method will not execute any query. Instead it will just return a struct with a `sql` key containing the plain string SQL that would have been executed and a `params` key with an array of params that would be included
	 * @distinct.hint           Whether or not the record set should be a 'distinct' select
	 * @selectFields.docdefault  []
	 * @filter.docdefault        {}
	 * @filterParams.docdefault  {}
	 * @extraFilters.docdefault  []
	 * @extraJoins.docdefault    []
	 */
	public any function selectData(
		  required string  objectName
		,          string  id
		,          array   selectFields        = []
		,          any     filter              = {}
		,          struct  filterParams        = {}
		,          array   extraFilters        = []
		,          array   savedFilters        = []
		,          string  orderBy             = ""
		,          string  groupBy             = ""
		,          boolean autoGroupBy         = false
		,          string  having              = ""
		,          numeric maxRows             = 0
		,          numeric startRow            = 1
		,          boolean useCache            = true
		,          boolean fromVersionTable    = false
		,          numeric specificVersion     = 0
		,          boolean allowDraftVersions  = $getRequestContext().showNonLiveContent()
		,          string  forceJoins          = ""
		,          array   extraJoins          = []
		,          boolean recordCountOnly     = false
		,          boolean getSqlAndParamsOnly = false
		,          boolean distinct            = false
	) autodoc=true {
		var args = _cleanupPropertyAliases( argumentCollection=arguments );

		var interceptorResult = _announceInterception( "preSelectObjectData", args );
		if ( IsBoolean( interceptorResult.abort ?: "" ) && interceptorResult.abort ) {
			return IsQuery( interceptorResult.returnValue ?: "" ) ? interceptorResult.returnValue : QueryNew('');
		}

		var objMeta = _getObject( args.objectName ).meta;
		var adapter = _getAdapter( objMeta.dsn );

		args.selectFields   = parseSelectFields( argumentCollection=args );

		if ( !args.allowDraftVersions && !args.fromVersionTable && objectIsVersioned( args.objectName ) ) {
			args.extraFilters.append( _getDraftExclusionFilter( args.objectname ) );
		}
		args.preparedFilter = _prepareFilter(
			  argumentCollection = args
			, adapter            = adapter
			, columnDefinitions  = objMeta.properties
		);

		if ( args.useCache ) {
			args.cachekey = args.objectName & "_" & Hash( LCase( Serialize( args ) ) );

			_announceInterception( "onCreateSelectDataCacheKey", args );

			var cachedResult = _getDefaultQueryCache().get( args.cacheKey );
			if ( !IsNull( cachedResult ) ) {
				return cachedResult;
			}
		}
		args.adapter     = adapter;
		args.objMeta     = objMeta;
		args.orderBy     = arguments.recordCountOnly ? "" : _parseOrderBy( args.orderBy, args.objectName, args.adapter );
		args.groupBy     = _autoAliasBareProperty( args.objectName, args.groupBy, args.adapter );
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
					, params = args.preparedFilter.params
				};
			}
			args.result = _runSql( sql=sql, dsn=args.objMeta.dsn, params=args.preparedFilter.params );
			if ( arguments.recordCountOnly ) {
				args.result = Val( args.result.record_count ?: "" );
			}
		}

		if ( args.useCache ) {
			_getDefaultQueryCache().set( args.cacheKey, args.result );
			_recordCacheSoThatWeCanClearThemWhenDataChanges(
				  objectName   = args.objectName
				, cacheKey     = args.cacheKey
				, filter       = args.preparedFilter.filter
				, filterParams = args.preparedFilter.filterParams
				, joins        = args.joins
			);
		}

		_announceInterception( "postSelectObjectData", args );

		return args.result;
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
	 * @useVersioning.docdefault     automatic
	 */
	public any function insertData(
		  required string  objectName
		, required struct  data
		,          boolean insertManyToManyRecords = false
		,          boolean isDraft                 = false
		,          boolean useVersioning           = objectIsVersioned( arguments.objectName )
		,          numeric versionNumber           = 0

	) autodoc=true {
		var interceptorResult = _announceInterception( "preInsertObjectData", arguments );

		if ( IsBoolean( interceptorResult.abort ?: "" ) && interceptorResult.abort ) {
			return interceptorResult.returnValue ?: "";
		}

		var args               = _cleanupPropertyAliases( argumentCollection=arguments );
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
		var requiresVersioning = args.useVersioning && objectIsVersioned( args.objectName );
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

		if ( StructKeyExists( obj.properties, dateCreatedField ) and not StructKeyExists( cleanedData, dateCreatedField ) ) {
			cleanedData[ dateCreatedField ] = rightNow;
		}
		if ( StructKeyExists( obj.properties, dateModifiedField ) and not StructKeyExists( cleanedData, dateModifiedField ) ) {
			cleanedData[ dateModifiedField ] = rightNow;
		}
		if ( StructKeyExists( obj.properties, idField ) ) {
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
							  sourceObject   = args.objectName
							, sourceProperty = key
							, sourceId       = newId
							, targetIdList   = manyToManyData[ key ]
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

		clearRelatedCaches(
			  objectName              = args.objectName
			, filter                  = ""
			, filterParams            = {}
			, clearSingleRecordCaches = false
		);

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
	 * @autodoc             true
	 * @objectName.hint     Name of the object in which to to insert records
	 * @selectDataArgs.hint Struct of arguments that are valid to pass to the [[presideobjectservice-selectdata]] method
	 * @fieldList.hint      Array of table field names that the select fields in the select statement should map to for the insert
	 */
	public numeric function insertDataFromSelect(
		  required string objectName
		, required struct selectDataArgs
		, required array  fieldList
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

		clearRelatedCaches(
			  objectName              = arguments.objectName
			, filter                  = ""
			, filterParams            = {}
			, clearSingleRecordCaches = false
		);

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
	 * @useVersioning.docdefault     auto
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

		transaction {
			if ( requiresVersioning ) {
				versionNumber = _getVersioningService().saveVersionForUpdate(
					  objectName           = arguments.objectName
					, id                   = arguments.id ?: NullValue()
					, filter               = preparedFilter.filter
					, filterParams         = preparedFilter.filterParams
					, data                 = cleanedData
					, manyToManyData       = manyToManyData
					, isDraft              = arguments.isDraft
					, versionNumber        = arguments.versionNumber ? arguments.versionNumber : getNextVersionNumber()
					, forceVersionCreation = arguments.forceVersionCreation
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
								  sourceObject   = arguments.objectName
								, sourceProperty = key
								, sourceId       = updatedId
								, targetIdList   = manyToManyData[ key ]
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

		clearRelatedCaches(
			  objectName   = arguments.objectName
			, filter       = preparedFilter.filter
			, filterParams = preparedFilter.filterParams
		);

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
	 * @objectName.hint     Name of the object from whose database table records are to be deleted
	 * @id.hint             ID of a record to delete
	 * @filter.hint         Filter for records to delete, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`
	 * @filterParams.hint   Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`
	 * @extraFilters.hint   An array of extra sets of filters. Each array should contain a structure with :code:`filter` and optional `code:`filterParams` keys.
	 * @forceDeleteAll.hint If no id or filter supplied, this must be set to **true** in order for the delete to process
	 */
	public numeric function deleteData(
		  required string  objectName
		,          string  id
		,          any     filter         = {}
		,          struct  filterParams   = {}
		,          array   extraFilters   = []
		,          array   savedFilters   = []
		,          boolean forceDeleteAll = false
	) autodoc=true {
		var interceptorResult = _announceInterception( "preDeleteObjectData", arguments );

		if ( IsBoolean( interceptorResult.abort ?: "" ) && interceptorResult.abort ) {
			return Val( interceptorResult.returnValue ?: 0 );
		}

		var args           = _cleanupPropertyAliases( argumentCollection=arguments );
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

		preparedFilter = _prepareFilter(
			  adapter           = adapter
			, columnDefinitions = obj.properties
			, argumentCollection = args
		);

		sql = adapter.getDeleteSql(
			  tableName  = obj.tableName
			, tableAlias = args.objectName
			, filter     = preparedFilter.filter
		);

		result = _runSql( sql=sql, dsn=obj.dsn, params=preparedFilter.params, returnType="info" );

		clearRelatedCaches(
			  objectName   = args.objectName
			, filter       = preparedFilter.filter
			, filterParams = preparedFilter.filterParams
		);

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
			var hasSortOrder = Len( Trim( relatedVia ) ) && getObjectProperties( relatedVia ).keyExists( "sort_order" );
			if ( hasSortOrder ) {
				selectDataArgs.orderBy = relatedVia & ".sort_order";
			}
		}

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
		  required string sourceObject
		, required string sourceProperty
		, required string sourceId
		, required string targetIdList
	) autodoc=true {
		var prop = getObjectProperty( arguments.sourceObject, arguments.sourceProperty );
		var targetObject = prop.relatedTo ?: "";
		var pivotTable   = prop.relatedVia ?: "";
		var sourceFk     = prop.relationshipIsSource ? prop.relatedViaSourceFk : prop.relatedViaTargetFk;
		var targetFk     = prop.relationshipIsSource ? prop.relatedViaTargetFk : prop.relatedViaSourceFk;

		if ( Len( Trim( pivotTable ) ) and Len( Trim( targetObject ) ) ) {
			var newRecords      = ListToArray( arguments.targetIdList );
			var anythingChanged = false;
			var hasSortOrder    = getObjectProperties( pivotTable ).keyExists( "sort_order" );
			var currentSelect   = [ "#targetFk# as targetId" ];

			if ( hasSortOrder ) {
				currentSelect.append( "sort_order" );
			}

			transaction {
				var currentRecords = selectData(
					  objectName   = pivotTable
					, selectFields = currentSelect
					, filter       = { "#sourceFk#" = arguments.sourceId }
				);

				for( var record in currentRecords ) {
					if ( newRecords.find( record.targetId ) && ( !hasSortOrder || newRecords.find( record.targetId ) == record.sort_order ) ) {
						ArrayDelete( newRecords, record.targetId );
					} else {
						anythingChanged = true;
						break;
					}
				}

				anythingChanged = anythingChanged || newRecords.len();

				if ( anythingChanged ) {
					deleteData(
						  objectName = pivotTable
						, filter     = { "#sourceFk#" = arguments.sourceId }
					);

					newRecords = ListToArray( arguments.targetIdList );
					for( var i=1; i <=newRecords.len(); i++ ) {
						insertData(
							  objectName    = pivotTable
							, useVersioning = false
							, data          = { "#sourceFk#"=arguments.sourceId, "#targetFk#"=newRecords[i], sort_order=i }
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
		var manyToManyData = {};

		for( var prop in props ) {
			if ( ( !arguments.selectFields.len() || arguments.selectFields.findNoCase( prop ) ) ) {
				if ( isManyToManyProperty( arguments.objectName, prop ) ) {

					var records = selectData(
						  objectName       = arguments.objectName
						, id               = arguments.id
						, selectFields     = [ "#prop#.id" ]
						, fromVersionTable = arguments.fromVersionTable
						, specificVersion  = arguments.specificVersion
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
		var hasSortOrder  = getObjectProperties( targetObject ).keyExists( "sort_order" );
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
	public query function getRecordVersions( required string objectName, required string id, string fieldName ) autodoc=true {
		var args = {};
		var idField = getIdField( arguments.objectName );

		for( var key in arguments ){ // we do this, because simply duplicating the arguments causes issues with the Argument type being more than a plain ol' structure
			args[ key ] = arguments[ key ];
		}

		args.append( {
			  objectName         = getVersionObjectName( arguments.objectName )
			, orderBy            = "_version_number desc"
			, useCache           = false
			, allowDraftVersions = true
		} );

		if ( args.keyExists( "fieldName" ) ) {
			args.filter       = "#idField# = :#idField# and _version_changed_fields like :_version_changed_fields";
			args.filterParams = { "#idField#" = arguments.id, _version_changed_fields = "%,#args.fieldName#,%" };
			args.delete( "fieldName" );
			args.delete( "id" );
		}

		return selectData( argumentCollection = args );
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
		_getCache().clearAll();
		_getDefaultQueryCache().clearAll();
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
		return getObjectAttribute( arguments.objectName, "dateCreatedField", "dateCreated" );
	}

	/**
	 * Returns the dateModified field name of the object
	 *
	 * @autodoc    true
	 * @objectName Name of the object whose dateModified field you wish to get
	 */
	public string function getDateModifiedField( required string objectName ) {
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

		if ( props.keyExists( arguments.propertyName ) ) {
			return props[ arguments.propertyName ];
		}

		for( var propName in props ) {
			var prop = props[ propName ];
			if ( ListFindNoCase( prop.aliases ?: "", arguments.propertyName ) ) {
				return prop;
			}
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

					if ( recordCount ) {
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

		switch ( arguments.type ) {
			case "numeric":
				return "spinner";
			case "boolean":
				return "yesNoSwitch";
		}

		if ( arguments.enum.len() ) {
			return "enumSelect";
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
		var cacheMaps   = _getCacheMaps();
		var cache       = _getDefaultQueryCache();
		var lockName    = _getInstanceId() & "cachemaps" & arguments.objectName;
		var idField     = getIdField( objectName );
		var keysToClear = [];
		var objIds      = "";
		var objId       = "";

		if ( StructKeyExists( cacheMaps, arguments.objectName ) ) {
			lock name=lockName type="exclusive" timeout=10 {
				if ( StructKeyExists( cacheMaps, arguments.objectName ) ) {
					keysToClear = StructKeyArray( cacheMaps[ arguments.objectName ].__complexFilter );
					StructClear( cacheMaps[ arguments.objectName ].__complexFilter );

					if ( IsStruct( arguments.filter ) and StructKeyExists( arguments.filter, "id" ) ) {
						objIds = arguments.filter.id;
					} else if ( IsStruct( arguments.filter ) and StructKeyExists( arguments.filter, idField ) ) {
						objIds = arguments.filter[ idField ];
					} else if ( StructKeyExists( arguments.filterParams, "id" ) ) {
						objIds = arguments.filterParams.id;
					} else if ( StructKeyExists( arguments.filterParams, idField ) ) {
						objIds = arguments.filterParams[ idField ];
					}

					if ( IsSimpleValue( objIds ) ) {
						objIds = ListToArray( objIds );
					}

					if ( IsArray( objIds ) and ArrayLen( objIds ) ) {
						for( objId in objIds ){
							if ( StructKeyExists( cacheMaps[ arguments.objectName ], objId ) ) {
								ArrayAppend( keysToClear, StructKeyArray( cacheMaps[ arguments.objectName ][ objId ] ), true );
								StructDelete( cacheMaps[ arguments.objectName ], objId );
							}
						}
					} else if ( arguments.clearSingleRecordCaches ) {
						for( objId in cacheMaps[ arguments.objectName ] ) {
							if ( objId neq "__complexFilter" ) {
								ArrayAppend( keysToClear, StructKeyArray( cacheMaps[ arguments.objectName ][ objId ] ), true );
							}
						}
						StructDelete( cacheMaps, arguments.objectName );
					}

					for( var key in keysToClear ){
						cache.clearQuiet( key );
					}
				}
			}
		}

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

	public array function parseSelectFields( required string objectName, required array selectFields, boolean includeAlias=true ) {
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

			fields[i] = _expandFormulaFields(
				  objectName = arguments.objectName
				, expression = fields[i]
				, dbAdapter  = adapter
				, includeAlias = arguments.includeAlias
			);

			if ( arguments.includeAlias ) {
				fields[i] = _autoAliasBareProperty(
					  objectName   = arguments.objectName
					, propertyName = fields[i]
					, dbAdapter    = adapter
				);
			}
		}

		arguments.selectFields = fields;
		_announceInterception( "postParseSelectFields", arguments );

		return fields;
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

		_setObjects( objects );
		_setDsns( StructKeyArray( dsns ) );
		_setupAliasCache();

		_announceInterception( state="postLoadPresideObjects", interceptData={ objects=objects } );
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

			if ( not StructKeyExists( arguments.data, key ) ) { // should use IsNull() arguments.data[key] but bug in Railo prevents this
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
		var key        = "";
		var cache      = _getCache();
		var cacheKey   = _removeDynamicElementsFromForeignObjectsCacheKey( "Detected foreign objects for generated SQL. Obj: #arguments.objectName#. Data: #StructKeyList( arguments.data )#. Fields: #ArrayToList( arguments.selectFields )#. Order by: #arguments.orderBy#. Filter: #IsStruct( filter ) ? StructKeyList( filter ) : filter#. Having: #having#" );
		var objects    = cache.get( cacheKey );

		if ( not IsNull( objects ) ) {
			return objects;
		}

		var all        = Duplicate( arguments.data );
		var fieldRegex = _getAlaisedFieldRegex();
		var entities   = _getEntityNames();
		var field      = "";
		var addMatches = function( required string input ){
			var matches = _reSearch( fieldRegex, arguments.input );
			if ( StructKeyExists( matches, "$2" ) ) {
				for( var match in matches.$2 ){
					var matchEntities = match.listToArray( "$" );
					var matched       = true;

					for( var entity in matchEntities ) {
						if ( !entities.keyExists( entity ) ) {
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

		objects = {}

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

		cache.set( cacheKey, objects );

		return objects;
	}

	private string function _removeDynamicElementsFromForeignObjectsCacheKey( required string cacheKey ) {
		var staticCacheKey = arguments.cacheKey;

		staticCacheKey = staticCacheKey.reReplaceNoCase( "[0-9a-f]{32}", "", "all" );
		staticCacheKey = staticCacheKey.reReplaceNoCase( "[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{16}", "", "all" );
		staticCacheKey = staticCacheKey.reReplaceNoCase( "field\s?\(.*?\)", "", "all" );

		return staticCacheKey;
	}

	private struct function _cleanupPropertyAliases() {
		var aliasCache = _getAliasCache();
		if ( aliasCache.isEmpty() ) {
			return Duplicate( arguments );
		}

		var args        = Duplicate( arguments );
		var aliasRegex  = _getAlaisedAliasRegex();

		var findAndReplace = function( plainString ) {
			if ( Len( aliasCache[ args.objectName ][ plainString ] ?: "" ) ) {
				return [ {
					  fullMatch     = plainString
					, replaceWith   = aliasCache[ args.objectName ][ plainString ]
					, aliasProperty = plainString
					, realProperty  = aliasCache[ args.objectName ][ plainString ]
				} ];
			}

			var matches = _reSearch( aliasRegex, plainString );
			var results = [];

			if ( matches.keyExists( "$1" ) ) {
				for( var i=1; i<=matches.$1.len(); i++ ) {
					var fullMatch   = matches.$1[i] & matches.$2[i] & matches.$6[i] & "." & matches.$7[i] & matches.$8[i] & matches.$9[i];
					var objPath     = matches.$2[i];
					var propName    = matches.$8[i];
					var objFromPath = _resolveObjectNameFromColumnJoinSyntax( args.objectName, objPath );

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

			return results;
		};
		var structKeyReplacer = function( theStruct ){
			for( var key in theStruct ) {
				var fAndRResult = findAndReplace( key );
				for( var r in fAndRResult ){
					var newKey = key.replace( r.fullMatch, r.replaceWith, "all" );
					theStruct[ newKey ] = theStruct[ key ];
					theStruct.delete( key );
				}
			}
		}
		var simpleReplacer = function( plainString, addAsAlias=false ) {
			var replaced    = plainString;
			var fAndRResult = findAndReplace( plainString );

			for( var r in fAndRResult ){
				replaced = replaced.replace( r.fullMatch, r.replaceWith, "all" );
			}
			if ( addAsAlias && fAndRResult.len() && !plainString.findNoCase( " as " ) ) {
				replaced &= " as " & fAndRResult[1].aliasProperty;
			}

			return replaced;
		}

		if ( args.keyExists( "selectFields" ) ) {
			for( var i=1; i<=args.selectFields.len(); i++ ) {
				args.selectFields[ i ] = simpleReplacer( args.selectFields[ i ], true );
			}
		}

		if ( args.keyExists( "filter" ) ) {
			if ( IsSimpleValue( args.filter ) ) {
				args.filter = simpleReplacer( args.filter );
			} else {
				structKeyReplacer( args.filter );
			}
		}

		if ( args.keyExists( "filterParams" ) ) {
			structKeyReplacer( args.filterParams );
		}

		if ( args.keyExists( "data" ) ) {
			structKeyReplacer( args.data );
		}

		if ( args.keyExists( "having" ) ) {
			args.having = simpleReplacer( args.having );
		}

		if ( args.keyExists( "orderBy" ) ) {
			args.orderBy = simpleReplacer( args.orderBy );
		}

		if ( args.keyExists( "groupBy" ) ) {
			args.groupBy = simpleReplacer( args.groupBy );
		}

		return args;
	}

	private array function _getJoinsFromJoinTargets(
		  required string  objectName
		, required array   joinTargets
		, required string  forceJoins
		, required boolean fromVersionTable
	) {
		var joins = [];

		if ( ArrayLen( arguments.joinTargets ) ) {
			var joinsCache    = _getCache();
			var joinsCacheKey = "SQL Joins for #arguments.objectName# with join targets: #ArrayToList( arguments.joinTargets )#. From version table: #arguments.fromVersionTable#. Forcing joins: [#arguments.forceJoins#]."

			joins = joinsCache.get( joinsCacheKey );

			if ( IsNull( joins ) ) {
				joins = _getRelationshipGuidance().calculateJoins( objectName = arguments.objectName, joinTargets = joinTargets, forceJoins = arguments.forceJoins );

				joinsCache.set( joinsCacheKey, joins );
			}
		}

		return joins;
	}

	private array function _convertObjectJoinsToTableJoins( required array joins, array extraJoins=[], array extraFilters=[], array savedFilters=[] ) {
		var tableJoins = [];
		var objJoin    = "";
		var objects    = _getObjects();
		var tableJoin  = "";

		for( objJoin in arguments.joins ){
			var join = {
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
				if ( manyToManyObjects.keyExists( join.joinFromObject ) ) {
					join.joinFromObject = getVersionObjectName( join.joinFromObject );
				}
				if ( manyToManyObjects.keyExists( join.joinToObject ) ) {
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

	private void function _recordCacheSoThatWeCanClearThemWhenDataChanges(
		  required string objectName
		, required string cacheKey
		, required any    filter
		, required struct filterParams
		, required array  joins
	) {
		var cacheMaps   = _getCacheMaps();
		var lockName    = _getInstanceId() & "cachemaps" & arguments.objectName;
		var idField     = getIdField( arguments.objectName );
		var fullIdField = "#arguments.objectName#.#idField#";
		var objId       = "";

		lock name=lockName type="exclusive" timeout=10 {
			cacheMaps[ arguments.objectName ] = cacheMaps[ arguments.objectName ] ?: { __complexFilter = {} };

			if ( IsStruct( arguments.filter ) ) {
				if ( arguments.filter.keyExists( "id" ) ) {
					objId = arguments.filter.id;
				} else if ( arguments.filter.keyExists( idField ) ) {
					objId = arguments.filter[ idField ];
				} else if ( arguments.filter.keyExists( fullIdField ) ) {
					objId = arguments.filter[ fullIdField ];
				} else if ( arguments.filter.keyExists( "#arguments.objectName#.id" ) ) {
					objId = arguments.filter[ "#arguments.objectName#.id" ];
				}
			} else {
				if ( arguments.filterParams.keyExists( "id" ) ) {
					objId = arguments.filterParams.id;
				} else if ( arguments.filterParams.keyExists( idField ) ) {
					objId = arguments.filterParams[ idField ];
				} else if ( arguments.filterParams.keyExists( fullIdField ) ) {
					objId = arguments.filterParams[ fullIdField ];
				} else if ( arguments.filterParams.keyExists( "#arguments.objectName#.id" ) ) {
					objId = arguments.filterParams[ "#arguments.objectName#.id" ];
				}
			}

			if ( IsStruct( objId ) ) {
				if ( Len( Trim( objId.value ?: "" ) ) ) {
					objId = ( objId.list ?: false ) ? ListToArray( objId.value, objId.separator ?: "," ) : [ objId.value ];
				}
			}

			if ( IsArray( objId ) ) {
				for( var id in objId ){
					cacheMaps[ arguments.objectName ][ id ][ arguments.cacheKey ] = 1;
				}
			} else if ( IsSimpleValue( objId ) and Len( Trim( objId) ) ) {
				cacheMaps[ arguments.objectName ][ objId ][ arguments.cacheKey ] = 1;
			} else {
				cacheMaps[ arguments.objectName ].__complexFilter[ arguments.cacheKey ] = 1;
			}

			for( var join in arguments.joins ) {
				var joinObj = join.joinToObject ?: "";

				cacheMaps[ joinObj ] = cacheMaps[ joinObj ] ?: { __complexFilter = {} };
				cacheMaps[ joinObj ].__complexFilter[ arguments.cacheKey ] = 1;
			}
		}
	}

	private string function _parseOrderBy( required string orderBy, required string objectName, required any dbAdapter ) {
		var items   = arguments.orderBy.listToArray();
		var rebuilt = [];

		for( var item in items ) {
			var propertyName = _expandFormulaFields( objectName=arguments.objectName, expression=Trim( ListFirst( item, " " ) ), dbAdapter=arguments.dbAdapter, includeAlias=false );
			var direction    = ListLen( item, " " ) > 1 ? " " & ListRest( item, " ") : "";
			var aliased      = _autoAliasBareProperty( arguments.objectName, propertyName, arguments.dbAdapter );

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

		if ( !_relationshipPathCalcCache.keyExists( cacheKey ) ) {
			_relationshipPathCalcCache[ cacheKey ] = _getRelationshipGuidance().resolveRelationshipPathToTargetObject(
				  sourceObject     = arguments.startObject
				, relationshipPath = arguments.joinSyntax
			);
		}

		return _relationshipPathCalcCache[ cacheKey ];
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
			  filter       = arguments.keyExists( "id" ) ? { "#idField#" = arguments.id } : arguments.filter
			, filterParams = arguments.filterParams
			, having       = arguments.having
		};
		if ( IsStruct( result.filter ) && ( arguments.extraFilters.len() || arguments.savedFilters.len() ) ) {
			result.filterParams.append( Duplicate( result.filter ) );
		}

		for( var savedFilter in arguments.savedFilters ){
			savedFilter = _getFilterService().getFilter( savedFilter );

			savedFilter.filter       = savedFilter.filter       ?: {};
			savedFilter.filterParams = savedFilter.filterParams ?: {};
			savedFilter.having       = savedFilter.having       ?: "";

			savedFilter = _cleanupPropertyAliases( argumentCollection=savedFilter, objectName=arguments.objectName );
			savedFilter.delete( "objectName" );

			result.filterParams.append( savedFilter.filterParams ?: {} );
			if ( IsStruct( savedFilter.filter ) ) {
				result.filterParams.append( savedFilter.filter );
			}

			result.filter = mergeFilters(
				  filter1    = result.filter
				, filter2    = savedFilter.filter
				, dbAdapter  = arguments.adapter
				, tableAlias = arguments.objectName
			);
			if ( Len( Trim( savedFilter.having ) ) ) {
				result.having = mergeFilters(
					  filter1    = result.having
					, filter2    = savedFilter.having
					, dbAdapter  = arguments.adapter
					, tableAlias = arguments.objectName
				);
			}
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
				var aliasedKey = _autoAliasBareProperty( objectName=arguments.objectName, propertyName=key, dbAdapter=arguments.adapter, escapeEntities=false );
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
				var aliasedKey = _autoAliasBareProperty( objectName=arguments.objectName, propertyName=key, dbAdapter=arguments.adapter, escapeEntities=false );
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

	private struct function _addGeneratedValues( required string operation, required string objectName, required struct data ) {
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

				var generatedValue = _generateValue( arguments.objectName, prop.generator, newData, prop );
				if ( !IsNull( generatedValue ) ) {
					generated[ propName ] = newData[ propName ] = generatedValue;
				}
			}
		}

		return generated;
	}

	private any function _generateValue( required string objectName, required string generator, required struct data, required struct prop ) {
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
						if ( arguments.data.keyExists( field ) ) {
							valueToHash &= arguments.data[ field ];
						} else {
							return;
						}
					}

					return Hash( valueToHash );
				}
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

	private string function _expandFormulaFields(
		  required string  objectName
		, required string  expression
		, required any     dbAdapter
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

	private string function _autoAliasBareProperty(
		  required string  objectName
		, required string  propertyName
		, required any     dbAdapter
		,          string  alias          = arguments.objectName
		,          boolean escapeEntities = true
	) {
		var objMeta       = _getObject( arguments.objectName ).meta;
		var barePropRegex = "^(" & objMeta.dbFieldList.replace( ",", "|", "all" ) & ")$";

		if ( arguments.propertyName.reFindNoCase( barePropRegex ) ) {
			if ( escapeEntities ) {
				return dbAdapter.escapeEntity( arguments.alias ) & "." & dbAdapter.escapeEntity( arguments.propertyName );
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

	private any function _getCache() {
		return _cache;
	}
	private void function _setCache( required any cache ) {
		_cache = arguments.cache;
	}

	private any function _getDefaultQueryCache() {
		return _defaultQueryCache;
	}
	private void function _setDefaultQueryCache( required any defaultQueryCache ) {
		_defaultQueryCache = arguments.defaultQueryCache;
	}

	private struct function _getCacheMaps() {
		return _cacheMaps;
	}
	private void function _setCacheMaps( required struct cacheMaps ) {
		_cacheMaps = arguments.cacheMaps;
	}

	private any function _getInterceptorService() {
		return _interceptorService;
	}
	private void function _setInterceptorService( required any IiterceptorService ) {
		_interceptorService = arguments.IiterceptorService;
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
}