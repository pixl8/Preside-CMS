component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @objectDirectories.inject      presidecms:directories:preside-objects
	 * @objectReader.inject           PresideObjectReader
	 * @sqlSchemaSynchronizer.inject  SqlSchemaSynchronizer
	 * @adapterFactory.inject         AdapterFactory
	 * @sqlRunner.inject              SqlRunner
	 * @relationshipGuidance.inject   RelationshipGuidance
	 * @presideObjectDecorator.inject PresideObjectDecorator
	 * @objectCache.inject            cachebox:SystemCache
	 * @defaultQueryCache.inject      cachebox:DefaultQueryCache
	 * @coldboxController.inject      coldbox
	 */
	public any function init(
		  required array objectDirectories
		, required any   objectReader
		, required any   sqlSchemaSynchronizer
		, required any   adapterFactory
		, required any   sqlRunner
		, required any   relationshipGuidance
		, required any   presideObjectDecorator
		, required any   objectCache
		, required any   defaultQueryCache
		, required any   coldboxController
	) output=false {
		_setObjectDirectories( arguments.objectDirectories );
		_setObjectReader( arguments.objectReader );
		_setSqlSchemaSynchronizer( arguments.sqlSchemaSynchronizer );
		_setAdapterFactory( arguments.adapterFactory );
		_setSqlRunner( arguments.sqlRunner );
		_setRelationshipGuidance( arguments.relationshipGuidance );
		_setPresideObjectDecorator( arguments.presideObjectDecorator );
		_setObjectCache( arguments.objectCache );
		_setDefaultQueryCache( arguments.defaultQueryCache );
		_setVersioningService( new VersioningService( this, arguments.coldboxController ) );
		_setCacheMaps( {} );

		_loadObjects();

		return this;
	}

// PUBLIC API METHODS
	public array function listObjects() output=false {
		var objects     = _getAllObjects();
		var objectNames = [];

		for( var objectName in objects ){
			if ( !IsSimpleValue( objects[ objectName ].instance ?: "" ) ) {
				objectNames.append( objectName );
			}
		}

		ArraySort( objectNames, "textnocase" );

		return objectNames;
	}

	public any function getObject( required string objectName ) output=false {
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

	public any function getObjectAttribute( required string objectName, required string attributeName, string defaultValue="" ) output=false {
		var obj = _getObject( arguments.objectName );

		return obj.meta[ arguments.attributeName ] ?: arguments.defaultValue;
	}

	public boolean function objectExists( required string objectName ) output=false {
		var objects = _getAllObjects();

		return StructKeyExists( objects, arguments.objectName );
	}

	public boolean function dataExists(
		  required string  objectName
		,          any     filter           = {}
		,          struct  filterParams     = {}
		,          boolean fromVersionTable = false
		,          string  maxVersion       = "HEAD"
		,          numeric specificVersion  = 0
	) output=false {
		var args = arguments;
		args.useCache     = false;
		args.selectFields = [ "1" ];

		return selectData( argumentCollection=args ).recordCount;
	}

	public boolean function fieldExists( required string objectName, required string fieldName ) output=false {
		var obj = _getObject( arguments.objectName );

		return StructKeyExists( obj.meta.properties, arguments.fieldName );
	}

	public numeric function deleteData(
		  required string  objectName
		,          string  id             = ""
		,          any     filter         = {}
		,          struct  filterParams   = {}
		,          boolean forceDeleteAll = false
	) output=false {
		var obj     = _getObject( arguments.objectName ).meta;
		var adapter = _getAdapter( obj.dsn );
		var sql     = "";
		var params  = [];
		var result = "";

		if ( Len( Trim( arguments.id ) ) ) {
			arguments.filter = { id = arguments.id };
		}

		if ( IsStruct( arguments.filter ) ) {
			params = _convertDataToQueryParams(
				  columnDefinitions = obj.properties
				, data              = arguments.filter
				, dbAdapter         = adapter
			);
		} else {
			params = _convertUserFilterParamsToQueryParams(
				  columnDefinitions = obj.properties
				, params            = arguments.filterParams
				, dbAdapter         = adapter
			);
		}

		if ( not Len( Trim( arguments.id ) ) and _isEmptyFilter( arguments.filter ) and not arguments.forceDeleteAll ) {
			throw(
				  type    = "PresideObjects.deleteAllProtection"
				, message = "A call to delete records in [#arguments.objectName#] was made without any filter which would lead to all records being deleted"
				, detail  = "If you wish to delete all records, you must set the [forceDeleteAll] argument of the [deleteData] method to true"
			);
		}

		sql = adapter.getDeleteSql(
			  tableName = obj.tableName
			, filter    = filter
		);

		result = _runSql( sql=sql, dsn=obj.dsn, params=params, returnType="info" );

		_clearRelatedCaches(
			  objectName   = arguments.objectName
			, filter       = arguments.filter
			, filterParams = arguments.filterParams
		);

		return Val( result.recordCount ?: 0 );
	}

	public any function insertData(
		  required string  objectName
		, required struct  data
		,          boolean insertManyToManyRecords = false
		,          boolean useVersioning           = objectIsVersioned( arguments.objectName )
		,          numeric versionNumber           = 0

	) output=false {
		var obj                = _getObject( arguments.objectName ).meta;
		var adapter            = _getAdapter( obj.dsn );
		var sql                = "";
		var key                = "";
		var params             = "";
		var result             = "";
		var newId              = "";
		var rightNow           = DateFormat( Now(), "yyyy-mm-dd" ) & " " & TimeFormat( Now(), "HH:mm:ss" );
		var cleanedData        = Duplicate( arguments.data );
		var manyToManyData     = {};
		var requiresVersioning = arguments.useVersioning && objectIsVersioned( arguments.objectName );

		for( key in cleanedData ){
			if ( arguments.insertManyToManyRecords and getObjectPropertyAttribute( objectName, key, "relationship", "none" ) eq "many-to-many" ) {
				manyToManyData[ key ] = cleanedData[ key ];
			}
			if ( not ListFindNoCase( obj.dbFieldList, key ) ) {
				StructDelete( cleanedData, key );
			}
		}

		if ( StructKeyExists( obj.properties, "datecreated" ) and not StructKeyExists( cleanedData, "datecreated" ) ) {
			cleanedData.datecreated = rightNow;
		}
		if ( StructKeyExists( obj.properties, "datemodified" ) and not StructKeyExists( cleanedData, "datemodified" ) ) {
			cleanedData.datemodified = rightNow;
		}
		if ( StructKeyExists( obj.properties, "id" ) and ( not StructKeyExists( cleanedData, "id" ) or not Len( Trim( cleanedData.id ) ) ) ) {
			param name="obj.properties.id.generator" default="UUID";
			newId = _generateNewIdWhenNecessary( generator=obj.properties.id.generator );
			if ( Len( Trim( newId ) ) ) {
				cleanedData.id = newId;
			}
		}

		transaction {
			if ( requiresVersioning ) {
				_getVersioningService().saveVersionForInsert(
					  objectName     = arguments.objectName
					, data           = cleanedData
					, manyToManyData = manyToManyData
					, versionNumber  = arguments.versionNumber ? arguments.versionNumber : getNextVersionNumber()
				);
			}

			sql    = adapter.getInsertSql( tableName = obj.tableName, insertColumns = StructKeyArray( cleanedData ) );
			params = _convertDataToQueryParams(
				  columnDefinitions = obj.properties
				, data              = cleanedData
				, dbAdapter         = adapter
			);

			result = _runSql( sql=sql[1], dsn=obj.dsn, params=params, returnType="info" );

			newId = Len( Trim( newId ) ) ? newId : ( result.generatedKey ?: "" );
			if ( Len( Trim( newId ) ) ) {
				for( key in manyToManyData ){
					syncManyToManyData(
						  sourceObject   = arguments.objectName
						, sourceProperty = key
						, sourceId       = newId
						, targetIdList   = manyToManyData[ key ]
					);
				}
			}
		}

		_clearRelatedCaches(
			  objectName              = arguments.objectName
			, filter                  = ""
			, filterParams            = {}
			, clearSingleRecordCaches = false
		);

		return newId;
	}

	public numeric function updateData(
		  required string  objectName
		, required struct  data
		,          string  id                      = ""
		,          any     filter                  = {}
		,          struct  filterParams            = {}
		,          boolean forceUpdateAll          = false
		,          boolean updateManyToManyRecords = false
		,          boolean useVersioning           = objectIsVersioned( arguments.objectName )
		,          numeric versionNumber           = 0
	) output=false {
		var obj                = _getObject( arguments.objectName ).meta;
		var adapter            = _getAdapter( obj.dsn );
		var sql                = "";
		var result             = "";
		var params             = [];
		var joinTargets        = "";
		var joins              = [];
		var cleanedData        = Duplicate( arguments.data );
		var manyToManyData     = {}
		var key                = "";
		var requiresVersioning = arguments.useVersioning && objectIsVersioned( arguments.objectName );

		for( key in cleanedData ){
			if ( arguments.updateManyToManyRecords and getObjectPropertyAttribute( objectName, key, "relationship", "none" ) eq "many-to-many" ) {
				manyToManyData[ key ] = cleanedData[ key ];
			}
			if ( not ListFindNoCase( obj.dbFieldList, key ) ) {
				StructDelete( cleanedData, key );
			}
		}

		if ( not Len( Trim( arguments.id ) ) and _isEmptyFilter( arguments.filter ) and not arguments.forceUpdateAll ) {
			throw(
				  type    = "PresideObjects.updateAllProtection"
				, message = "A call to update records in [#arguments.objectName#] was made without any filter which would lead to all records being updated"
				, detail  = "If you wish to update all records, you must set the [forceUpdateAll] argument of the [updateData] method to true"
			);
		}

		if ( StructKeyExists( obj.properties, "datemodified" ) and not StructKeyExists( cleanedData, "datemodified" ) ) {
			cleanedData.datemodified = DateFormat( Now(), "yyyy-mm-dd" ) & " " & TimeFormat( Now(), "HH:mm:ss" );
		}

		joinTargets = _extractForeignObjectsFromArguments( objectName=arguments.objectName, filter=arguments.filter, data=cleanedData );
		if ( ArrayLen( joinTargets ) ) {
			joins = _getRelationshipGuidance().calculateJoins( objectName = arguments.objectName, joinTargets = joinTargets );
			joins = _convertObjectJoinsToTableJoins( joins );
		}

		if ( Len( Trim( arguments.id ) ) ) {
			arguments.filter = { id = arguments.id };
		}

		if ( IsStruct( arguments.filter ) ) {
			params = _convertDataToQueryParams(
				  columnDefinitions = obj.properties
				, data              = arguments.filter
				, dbAdapter         = adapter
			);
		} else {
			params = _convertUserFilterParamsToQueryParams(
				  columnDefinitions = obj.properties
				, params            = arguments.filterParams
				, dbAdapter         = adapter
			);
		}

		transaction {
			if ( requiresVersioning ) {
				_getVersioningService().saveVersionForUpdate(
					  objectName     = arguments.objectName
					, id             = arguments.id
					, filter         = arguments.filter
					, filterParams   = arguments.filterParams
					, data           = cleanedData
					, manyToManyData = manyToManyData
					, versionNumber  = arguments.versionNumber ? arguments.versionNumber : getNextVersionNumber()
				);
			}

			params = _arrayMerge( params, _convertDataToQueryParams(
				  columnDefinitions = obj.properties
				, data              = cleanedData
				, dbAdapter         = adapter
				, preFix            = "set__"
			) );

			sql = adapter.getUpdateSql(
				  tableName     = obj.tableName
				, tableAlias    = arguments.objectName
				, updateColumns = StructKeyArray( cleanedData )
				, filter        = filter
				, joins         = joins
			);

			result = _runSql( sql=sql, dsn=obj.dsn, params=params, returnType="info" );

			if ( StructCount( manyToManyData ) ) {
				var updatedRecords = [];

				if ( Len( Trim( arguments.id ) ) ) {
					updatedRecords = [ arguments.id ];
				} else {
					updatedRecords = selectData(
						  objectName   = arguments.objectName
						, selectFields = [ "id" ]
						, filter       = arguments.filter
						, filterParams = arguments.filterParams
					);
					updatedRecords = ListToArray( updatedRecords.id );
				}

				for( key in manyToManyData ){
					for( var updatedId in updatedRecords ) {
						syncManyToManyData(
							  sourceObject   = arguments.objectName
							, sourceProperty = key
							, sourceId       = updatedId
							, targetIdList   = manyToManyData[ key ]
						);
					}
				}
			}
		}

		_clearRelatedCaches(
			  objectName   = arguments.objectName
			, filter       = arguments.filter
			, filterParams = arguments.filterParams
		);

		return Val( result.recordCount ?: 0 );
	}

	public boolean function syncManyToManyData(
		  required string sourceObject
		, required string sourceProperty
		, required string sourceId
		, required string targetIdList
	) output=false {
		var prop = getObjectProperty( arguments.sourceObject, arguments.sourceProperty );
		var targetObject = prop.relatedTo ?: "";
		var pivotTable   = prop.relatedVia ?: "";

		if ( Len( Trim( pivotTable ) ) and Len( Trim( targetObject ) ) ) {
			var newRecords      = ListToArray( arguments.targetIdList );
			var anythingChanged = false;

			transaction {
				var currentRecords = selectData(
					  objectName   = pivotTable
					, selectFields = [ "#targetObject# as targetId", "sort_order" ]
					, filter       = { "#arguments.sourceObject#" = arguments.sourceId }
				);

				for( var record in currentRecords ) {
					if ( newRecords.find( record.targetId ) && newRecords.find( record.targetId ) == record.sort_order ) {
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
						, filter     = { "#arguments.sourceObject#" = arguments.sourceId }
					);

					newRecords = ListToArray( arguments.targetIdList );
					for( var i=1; i <=newRecords.len(); i++ ) {
						insertData(
							  objectName    = pivotTable
							, data          = { "#arguments.sourceObject#" = arguments.sourceId, "#targetObject#" = newRecords[i], sort_order=i }
							, useVersioning = false
						);
					}
				}
			}
		}

		return true;
	}

	public query function selectData(
		  required string  objectName
		,          string  id               = ""
		,          array   selectFields     = []
		,          any     filter           = {}
		,          struct  filterParams     = {}
		,          string  orderBy          = ""
		,          string  groupBy          = ""
		,          numeric maxRows          = 0
		,          numeric startRow         = 1
		,          boolean useCache         = true
		,          boolean fromVersionTable = false
		,          string  maxVersion       = "HEAD"
		,          numeric specificVersion  = 0
		,          string  forceJoins       = ""

	) output=false {
		var result     = "";
		var queryCache = "";
		var cachekey   = "";

		if ( arguments.useCache ) {
			queryCache = _getDefaultQueryCache();
			cachekey   = arguments.objectName & "_" & Hash( LCase( SerializeJson( arguments ) ) );
			result     = queryCache.get( cacheKey );

			if ( not IsNull( result ) ) {
				return result;
			}
		}

		var sql                  = "";
		var obj                  = _getObject( arguments.objectName ).meta;
		var adapter              = _getAdapter( obj.dsn );
		var params               = [];
		var joinTargets          = _extractForeignObjectsFromArguments( objectName=arguments.objectName, selectFields=arguments.selectFields, filter=arguments.filter, orderBy=arguments.orderBy );
		var joins                = [];
		var i                    = "";
		var compiledSelectFields = Duplicate( arguments.selectFields );

		if ( Len( Trim( arguments.id ) ) ) {
			arguments.filter = { id = arguments.id };
		}

		if ( IsStruct( arguments.filter ) ) {
			params = _convertDataToQueryParams(
				  columnDefinitions = obj.properties
				, data              = arguments.filter
				, dbAdapter         = adapter
			);
		} else {
			params = _convertUserFilterParamsToQueryParams(
				  columnDefinitions = obj.properties
				, params            = arguments.filterParams
				, dbAdapter         = adapter
			);
		}

		if ( not ArrayLen( compiledSelectFields ) ) {
			compiledSelectFields = _dbFieldListToSelectFieldsArray( obj.dbFieldList, arguments.objectName, adapter );
		}

		if ( ArrayLen( joinTargets ) ) {
			var joinsCache    = _getObjectCache();
			var joinsCacheKey = "SQL Joins for #arguments.objectName# with join targets: #ArrayToList( joinTargets )#"

			joins = joinsCache.get( joinsCacheKey );

			if ( IsNull( joins ) ) {
				joins = _getRelationshipGuidance().calculateJoins( objectName = arguments.objectName, joinTargets = joinTargets, forceJoins = arguments.forceJoins );

				joinsCache.set( joinsCacheKey, joins );
			}
		}

		if ( arguments.fromVersionTable && objectIsVersioned( arguments.objectName ) ) {
			result = _selectFromVersionTables(
				  objectName        = arguments.objectName
				, originalTableName = obj.tableName
				, joins             = joins
				, selectFields      = arguments.selectFields
				, maxVersion        = arguments.maxVersion
				, specificVersion   = arguments.specificVersion
				, filter            = arguments.filter
				, params            = params
				, orderBy           = arguments.orderBy
				, groupBy           = arguments.groupBy
				, maxRows           = arguments.maxRows
				, startRow          = arguments.startRow
			);
		} else {
			sql = adapter.getSelectSql(
				  tableName     = obj.tableName
				, tableAlias    = arguments.objectName
				, selectColumns = compiledSelectFields
				, filter        = arguments.filter
				, joins         = _convertObjectJoinsToTableJoins( joins )
				, orderBy       = arguments.orderBy
				, groupBy       = arguments.groupBy
				, maxRows       = arguments.maxRows
				, startRow      = arguments.startRow
			);
			result = _runSql( sql=sql, dsn=obj.dsn, params=params );
		}


		if ( arguments.useCache ) {
			queryCache.set( cacheKey, result );
			_recordCacheSoThatWeCanClearThemWhenDataChanges(
				  objectName   = arguments.objectName
				, cacheKey     = cacheKey
				, filter       = arguments.filter
				, filterParams = arguments.filterParams
				, joinTargets  = joinTargets
			);
		}

		return result;
	}

	public query function selectManyToManyData(
		  required string  objectName
		, required string  propertyName
		,          array   selectFields = []
		,          string  orderBy      = ""
	) output=false {
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

		if ( not Len( Trim( selectDataArgs.orderBy ) ) ) {
			var relatedVia = getObjectPropertyAttribute( arguments.objectName, arguments.propertyName, "relatedVia", "" );
			if ( Len( Trim( relatedVia ) ) ) {
				selectDataArgs.orderBy = relatedVia & ".sort_order"
			}
		}

		return selectData( argumentCollection = selectDataArgs );
	}

	public query function getRecordVersions( required string objectName, required string id, string fieldName ) output=false {
		var args = {};

		for( var key in arguments ){ // we do this, because simply duplicating the arguments causes issues with the Argument type being more than a plain ol' structure
			args[ key ] = arguments[ key ];
		}

		args.append( {
			  objectName   = getVersionObjectName( arguments.objectName )
			, orderBy      = "_version_number desc"
			, useCache     = false
		} );

		if ( args.keyExists( "fieldName" ) ) {
			args.filter       = "id = :id and _version_changed_fields like :_version_changed_fields";
			args.filterParams = { id = arguments.id, _version_changed_fields = "%,#args.fieldName#,%" };
			args.delete( "fieldName" );
			args.delete( "id" );
		}

		return selectData( argumentCollection = args );
	}

	public struct function getDeNormalizedManyToManyData(
		  required string  objectName
		, required string  id
		,          boolean fromVersionTable = false
		,          string  maxVersion       = "HEAD"
		,          numeric specificVersion  = 0
	) output=false {
		var props          = getObjectProperties( arguments.objectName );
		var manyToManyData = {};

		for( var prop in props ) {
			if ( isManyToManyProperty( arguments.objectName, prop ) ) {

				var records = selectData(
					  objectName       = arguments.objectName
					, id               = arguments.id
					, selectFields     = [ "#prop#.id" ]
					, fromVersionTable = arguments.fromVersionTable
					, maxVersion       = arguments.maxVersion
					, specificVersion  = arguments.specificVersion
				);

				manyToManyData[ prop ] = records.recordCount ? ValueList( records.id ) : "";
			}
		}

		return manyToManyData;
	}

	public any function getObjectProperties( required string objectName ) output=false {
		return _getObject( arguments.objectName ).meta.properties;
	}

	public any function getObjectProperty( required string objectName, required string propertyName ) output=false {
		return _getObject( arguments.objectName ).meta.properties[ arguments.propertyName ];
	}

	public string function getObjectPropertyAttribute( required string objectName, required string propertyName, required string attributeName, string defaultValue="" ) output=false {
		var obj = _getObject( arguments.objectName );

		return obj.meta.properties[ arguments.propertyName ][ arguments.attributeName ] ?: arguments.defaultValue;
	}

	public boolean function isPageType( required string objectName ) output=false {
		var objMeta = _getObject( arguments.objectName ).meta;

		return IsBoolean( objMeta.isPageType ?: "" ) && objMeta.isPageType;
	}

	public string function getResourceBundleUriRoot( required string objectName ) output=false {
		if ( objectExists( arguments.objectName ) ) {
			return ( isPageType( arguments.objectName ) ? "page-types" : "preside-objects" ) & ".#arguments.objectName#:";
		}
		return "cms:";
	}

	public boolean function isManyToManyProperty( required string objectName, required string propertyName ) output=false {
		return getObjectPropertyAttribute( arguments.objectName, arguments.propertyName, "relationship", "" ) == "many-to-many";
	}

	public string function getVersionObjectName( required string sourceObjectName ) output=false {
		var obj = _getObject( arguments.sourceObjectName );

		return obj.meta.versionObjectName;
	}

	public any function getDbAdapterForObject( required string objectName ) output=false {
		var obj = _getObject( arguments.objectName ).meta;

		return _getAdapter( obj.dsn );
	}

	public void function reload() output=false {
		_getObjectCache().clearAll();
		_getDefaultQueryCache().clearAll();
		_loadObjects();
	}

	public void function dbSync() output=false {
		_getSqlSchemaSynchronizer().synchronize(
			  dsns    = _getAllDsns()
			, objects = _getAllObjects()
		);
	}

	public array function listForeignObjectsBlockingDelete( required string objectName, required any recordId ) output=false {
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
				if ( join.type == "one-to-many" && join.ondelete !== "cascade" ) {
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

	public numeric function deleteRelatedData( required string objectName, required any recordId ) output=false {
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

	public string function getDefaultFormControlForPropertyAttributes( string type="string", string dbType="varchar", string relationship="none", string relatedTo="", numeric maxLength=0 ) output=false {
		switch( arguments.relationship ){
			case "many-to-one" :
				return arguments.relatedTo == "asset" ? "assetPicker" : "manyToOneSelect";
			case "many-to-many":
				return arguments.relatedTo == "asset" ? "assetPicker" : "manyToManySelect";
		}

		switch ( arguments.type ) {
			case "numeric":
				return "spinner";
			case "boolean":
				return "yesNoSwitch";
			case "date":
				return "datePicker";
		}

		switch( arguments.dbType ){
			case "text":
			case "longtext":
			case "clob":
				return "richeditor";
		}

		if ( maxLength gte 200 ) {
			return "textarea";
		}

		return "textinput";
	}

	public boolean function objectIsVersioned( required string objectName ) output=false {
		var obj = _getObject( objectName );

		return IsBoolean( obj.meta.versioned ?: "" ) && obj.meta.versioned;
	}

	public numeric function getNextVersionNumber() output=false {
		return _getVersioningService().getNextVersionNumber();
	}


// PRIVATE HELPERS
	private void function _loadObjects() output=false {
		var objectPaths   = _getAllObjectPaths();
		var cache         = _getObjectCache();
		var objPath       = "";
		var objects       = {};
		var obj           = "";
		var objName       = "";
		var dsns          = {};

		for( objPath in objectPaths ){
			objName      = ListLast( objPath, "/" );
			obj          = {};
			obj.instance = CreateObject( "component", objPath );
			obj.meta     = _getObjectReader().readObject( obj.instance );

			objects[ objName ] = objects[ objName ] ?: [];
			objects[ objName ].append( obj );
			dsns[ obj.meta.dsn ] = 1;
		}
		if ( StructCount( objects ) ) {
			objects = _mergeObjects( objects );
			_getRelationshipGuidance().setupRelationships( objects );
			_getVersioningService().setupVersioningForVersionedObjects( objects, StructKeyArray( dsns )[1] );
		}

		cache.set( "PresideObjectService: objects", objects );
		cache.set( "PresideObjectService: dsns"   , StructKeyArray( dsns ) );
	}

	private struct function _mergeObjects( required struct unMergedObjects ) output=false {
		var merged = {};
		var merger = new Merger();

		for( var objName in unMergedObjects ) {
			merged[ objName ] = unMergedObjects[ objName ][ 1 ];

			for( var i=2; i lte unMergedObjects[ objName ].len(); i++ ) {
				merged[ objName ] = new Merger().mergeObjects( merged[ objName ], unMergedObjects[ objName ][ i ] );
			}
		}
		return merged;
	}

	private struct function _getAllObjects() output=false {
		var cache = _getObjectCache();

		if ( not cache.lookup( "PresideObjectService: objects" ) ) {
			_loadObjects();
		}

		return _getObjectCache().get( "PresideObjectService: objects" );
	}

	private array function _getAllDsns() output=false {
		var cache = _getObjectCache();

		if ( not cache.lookup( "PresideObjectService: dsns" ) ) {
			_loadObjects();
		}

		return _getObjectCache().get( "PresideObjectService: dsns" );
	}

	private struct function _getObject( required string objectName ) output=false {
		var objects = _getAllObjects();

		if ( not StructKeyExists( objects, arguments.objectName ) ) {
			throw( type="PresideObjectService.missingObject", message="Object [#arguments.objectName#] does not exist" );
		}

		return objects[ arguments.objectName ];
	}

	private array function _getAllObjectPaths() output=false {
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

	private array function _convertDataToQueryParams( required struct columnDefinitions, required struct data, required any dbAdapter, string prefix="", string tableAlias="" ) {
		var key        = "";
		var params     = [];
		var param      = "";
		var objectName = "";
		var cols       = "";
		var i          = 0;
		var paramName  = "";
		var dataType   = "";

		for( key in arguments.data ){
			if ( ListLen( key, "." ) == 2 && ListFirst( key, "." ) != arguments.tableAlias ) {
				objectName = ListFirst( key, "." );

				if ( arguments.columnDefinitions.keyExists( objectName ) && arguments.columnDefinitions[ objectName ].relatedTo != "none" ) {
					objectName = arguments.columnDefinitions[ objectName ].relatedTo;
				}


				if ( objectExists( objectName ) ) {
					cols = _getObject( objectName ).meta.properties;
				}
			} else {
				cols = arguments.columnDefinitions;
			}

			paramName = arguments.prefix & Replace( key, ".", "__", "all" );
			dataType  = arguments.dbAdapter.sqlDataTypeToCfSqlDatatype( cols[ ListLast( key, "." ) ].dbType );


			if ( not StructKeyExists( arguments.data,  key ) ) { // should use IsNull() arguments.data[key] but bug in Railo prevents this
				param = {
					  name  = paramName
					, value = NullValue()
					, type  = dataType
					, null  = true
				};

				ArrayAppend( params, param );
			} else if ( IsArray( arguments.data[ key ] ) ) {
				for( i=1; i lte ArrayLen(  arguments.data[ key ] ); i++ ){
					param = {
						  name  = paramName & "__" & i
						, value = arguments.data[ key ][ i ]
						, type  = dataType
					};

					ArrayAppend( params, param );
				}

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

	private array function _convertUserFilterParamsToQueryParams( required struct columnDefinitions, required struct params, required any dbAdapter ) output=false {
		var key        = "";
		var params     = [];
		var param      = "";
		var objectName = "";
		var cols       = "";
		var i          = 0;
		var paramName  = "";
		var dataType   = "";

		for( key in arguments.params ){
			param     = arguments.params[ key ];
			paramName = Replace( key, ".", "__", "all" );

			if ( IsStruct( param ) ) {
				StructAppend( param, { name=paramName } );
			} else {
				param = {
					  name  = paramName
					, value = param
				};
			}

			if ( not StructKeyExists( param, "type" ) ) {
				if ( ListLen( key, "." ) eq 2 ) {
					cols = _getObject( ListFirst( key, "." ) ).meta.properties;
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
		,          any    filter       = {}
		,          struct data         = {}
		,          array  selectFields = []
		,          string orderBy      = ""

	) output=false {
		var key        = "";
		var cache      = _getObjectCache();
		var cacheKey   = "Detected foreign objects for generated SQL. Obj: #arguments.objectName#. Data: #StructKeyList( arguments.data )#. Fields: #ArrayToList( arguments.selectFields )#. Order by: #arguments.orderBy#. Filter: #IsStruct( arguments.filter ) ? StructKeyList( arguments.filter ) : arguments.filter#"
		var objects    = cache.get( cacheKey );

		if ( not IsNull( objects ) ) {
			return objects;
		}

		var all        = Duplicate( arguments.data );
		var fieldRegex = _getAlaisedFieldRegex();
		var field      = "";
		var matches    = "";
		var match      = "";

		objects = {}

		if ( IsStruct( arguments.filter ) ) {
			StructAppend( all, arguments.filter );
		}

		for( key in all ) {
			if ( ListLen( key, "." ) eq 2 ) {
				objects[ ListFirst( key, "." ) ] = 1;
			}
		}

		for( field in arguments.selectFields ){
			matches = _reSearch( fieldRegex, field );
			if ( StructKeyExists( matches, "$2" ) ) {
				for( match in matches.$2 ){
					objects[ match ] = 1;
				}
			}
		}
		for( field in ListToArray( arguments.orderBy ) ){
			matches = _reSearch( fieldRegex, ListFirst( field, " " ) );
			if ( StructKeyExists( matches, "$2" ) ) {
				for( match in matches.$2 ){
					objects[ match ] = 1;
				}
			}
		}
		if ( isSimpleValue( arguments.filter ) ) {
			matches = _reSearch( fieldRegex, arguments.filter );
			if ( StructKeyExists( matches, "$2" ) ) {
				for( match in matches.$2 ){
					objects[ match ] = 1;
				}
			}
		}


		StructDelete( objects, arguments.objectName );
		objects = StructKeyArray( objects );

		cache.set( cacheKey, objects );

		return objects;
	}

	private array function _convertObjectJoinsToTableJoins( required array objectJoins ) output=false {
		var tableJoins = [];
		var objJoin = "";
		var objects = _getAllObjects();
		var tableJoin = "";

		for( objJoin in arguments.objectJoins ){
			var join = {
				  tableName         = objects[ objJoin.joinToObject ].meta.tableName
				, tableAlias        = objJoin.tableAlias ?: objJoin.joinToObject
				, tableColumn       = objJoin.joinToProperty
				, joinToTable       = objJoin.joinFromObject
				, joinToColumn      = objJoin.joinFromProperty
				, type              = objJoin.type
			};

			if ( IsBoolean( objJoin.addVersionClause ?: "" ) && objJoin.addVersionClause ) {
				join.additionalClauses = "#join.tableAlias#._version_number = #join.joinToTable#._version_number";
			}

			tableJoins.append( join );
		}

		return tableJoins;
	}

	private query function _selectFromVersionTables(
		  required string  objectName
		, required string  originalTableName
		, required array   joins
		, required array   selectFields
		, required string  maxVersion
		, required numeric specificVersion
		, required any     filter
		, required array   params
		, required string  orderBy
		, required string  groupBy
		, required numeric maxRows
		, required numeric startRow
	) output=false {
		var adapter              = getDbAdapterForObject( arguments.objectName );
		var versionObj           = _getObject( getVersionObjectName( arguments.objectName ) ).meta;
		var versionTableName     = versionObj.tableName;
		var alteredJoins         = _alterJoinsToUseVersionTables( arguments.joins, arguments.originalTableName, versionTableName );
		var compiledSelectFields = Duplicate( arguments.selectFields );
		var compiledFilter       = Duplicate( arguments.filter );
		var sql                  = "";
		var versionFilter        = "";
		var versionCheckJoin     = "";
		var versionCheckFilter   = "";

		if ( not ArrayLen( arguments.selectFields ) ) {
			compiledSelectFields = _dbFieldListToSelectFieldsArray( versionObj.dbFieldList, arguments.objectName, adapter );
		}

		if ( arguments.specificVersion ) {
			versionFilter = { "#arguments.objectName#._version_number" = arguments.specificVersion };
			compiledFilter = _mergeFilters( compiledFilter, versionFilter, adapter, arguments.objectName );

			arguments.params = _arrayMerge( arguments.params, _convertDataToQueryParams(
				  columnDefinitions = versionObj.properties
				, data              = versionFilter
				, dbAdapter         = adapter
				, tableAlias        = arguments.objectName
			) );
		} else {
			versionCheckJoin   = _getVersionCheckJoin( versionTableName, arguments.objectName, adapter );
			versionCheckFilter = "_latestVersionCheck.id is null";

			if ( ReFind( "^[1-9][0-9]*$", arguments.maxVersion ) ) {
				versionCheckJoin.additionalClauses &= " and _latestVersionCheck._version_number <= #arguments.maxVersion#";
				versionCheckFilter &= " and #arguments.objectName#._version_number <= #arguments.maxVersion#";
			}
			ArrayAppend( alteredJoins, versionCheckJoin );

			compiledFilter = _mergeFilters( compiledFilter, versionCheckFilter, adapter, arguments.objectName );
		}

		sql = adapter.getSelectSql(
			  tableName     = versionTableName
			, tableAlias    = arguments.objectName
			, selectColumns = compiledSelectFields
			, filter        = compiledFilter
			, joins         = alteredJoins
			, orderBy       = arguments.orderBy
			, groupBy       = arguments.groupBy
			, maxRows       = arguments.maxRows
			, startRow      = arguments.startRow
		);

		return _runSql( sql=sql, dsn=versionObj.dsn, params=arguments.params );
	}

	private struct function _getVersionCheckJoin( required string tableName, required string tableAlias, required any adapter ) output=false {
		return {
			  tableName         = arguments.tableName
			, tableAlias        = "_latestVersionCheck"
			, tableColumn       = "id"
			, joinToTable       = arguments.tableAlias
			, joinToColumn      = "id"
			, type              = "left"
			, additionalClauses = "#adapter.escapeEntity( '_latestVersionCheck' )#.#adapter.escapeEntity( '_version_number' )# > #adapter.escapeEntity( arguments.tableAlias )#.#adapter.escapeEntity( '_version_number' )#"
		}
	}

	private array function _alterJoinsToUseVersionTables(
		  required array  joins
		, required string originalTableName
		, required string versionTableName
	) output=false {
		var manyToManyObjects = {};
		for( var join in arguments.joins ){
			if ( Len( Trim( join.manyToManyProperty ?: "" ) ) ) {
				manyToManyObjects[ join.joinToObject ] = 1;
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
					join.joinToObject = getVersionObjectName( join.joinToObject );
					join.addVersionClause = true;
				}
			}
		}

		return _convertObjectJoinsToTableJoins( arguments.joins );
	}

	private array function _dbFieldListToSelectFieldsArray( required string fieldList, required string tableAlias, required any dbAdapter ) output=false {
		var fieldArray   = ListToArray( arguments.fieldList );
		var escapedAlias = dbAdapter.escapeEntity( arguments.tableAlias );

		for( var i=1; i <= fieldArray.len(); i++ ){
			fieldArray[i] = escapedAlias & "." & dbAdapter.escapeEntity( fieldArray[i] );
		}

		return fieldArray;
	}

	private string function _mergeFilters( required any filter1, required any filter2, required any dbAdapter, required string tableAlias ) output=false {
		var parsed1 = arguments.dbAdapter.getClauseSql( arguments.filter1, arguments.tableAlias );
		var parsed2 = arguments.dbAdapter.getClauseSql( arguments.filter2, arguments.tableAlias );

		parsed1 = ReReplace( parsed1, "^\s*where ", "" );
		parsed2 = ReReplace( parsed2, "^\s*where ", "" );

		if ( Len( Trim( parsed1 ) ) && Len( Trim( parsed2 ) ) ) {
			return "(" & parsed1 & ") and (" & parsed2 & ")";
		}

		return Len( Trim( parsed1 ) ) ? parsed1 : parsed2;
	}

	private string function _generateNewIdWhenNecessary( required string generator ) output=false {
		switch( arguments.generator ){
			case "UUID": return CreateUUId();
		}

		return "";
	}

	private array function _arrayMerge( required array arrayA, required array arrayB ) output=false {
		var newArray = Duplicate( arguments.arrayA );
		var node     = "";

		for( node in arguments.arrayB ){
			ArrayAppend( newArray, node );
		}

		return newArray;
	}

	private string function _getAlaisedFieldRegex() output=false {
		if ( not StructKeyExists( this, "_aliasedFieldRegex" ) ) {
			var entities = {};

			for( var objName in _getAllObjects() ){
				entities[ objName ] = 1;

				for( var propertyName in getObjectProperties( objName ) ) {
					entities[ propertyName ] = 1;
				}
			}
			entities = StructKeyList( entities, "|" );

			_aliasedFieldRegex = "(^|\s|,|\(,\))((#entities#)(\$(#entities#))*)\.([a-zA-Z_][a-zA-Z0-9_]*)(\s|$|\)|,)";
		}

		return _aliasedFieldRegex;
	}

	private struct function _reSearch( required string regex, required string text ) output=false {
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

	private boolean function _isEmptyFilter( required any filter ) output=false {
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
		, required array  joinTargets
	) output=false {
		var cacheMaps = _getCacheMaps();
		var objId     = "";
		var id        = "";
		var joinObj   = "";

		if ( not StructKeyExists( cacheMaps, arguments.objectName ) ) {
			cacheMaps[ arguments.objectName ] = {
				__complexFilter = {}
			};
		}

		if ( IsStruct( arguments.filter ) and StructKeyExists( arguments.filter, "id" ) ) {
			objId = arguments.filter.id;
		} elseif ( StructKeyExists( arguments.filterParams, "id" ) ) {
			objId = arguments.filterParams.id;
		}

		if ( IsStruct( objId ) ) {
			if ( Len( Trim( objId.value ?: "" ) ) ) {
				objId = ( objId.list ?: false ) ? ListToArray( objId.value, objId.separator ?: "," ) : [ objId.value ];
			}
		}

		if ( IsArray( objId ) ) {
			for( id in objId ){
				cacheMaps[ arguments.objectName ][ id ][ arguments.cacheKey ] = 1;
			}
		} elseif ( IsSimpleValue( objId ) and Len( Trim( objId) ) ) {
			cacheMaps[ arguments.objectName ][ objId ][ arguments.cacheKey ] = 1;
		} else {
			cacheMaps[ arguments.objectName ].__complexFilter[ arguments.cacheKey ] = 1;
		}

		for( joinObj in arguments.joinTargets ) {
			if ( not StructKeyExists( cacheMaps, joinObj ) ) {
				cacheMaps[ joinObj ] = {
					__complexFilter = {}
				};
			}
			cacheMaps[ joinObj ].__complexFilter[ arguments.cacheKey ] = 1;
		}
	}

	private void function _clearRelatedCaches(
		  required string  objectName
		, required any     filter
		, required struct  filterParams
		,          boolean clearSingleRecordCaches = true
	) output=false {
		var cacheMaps   = _getCacheMaps();
		var keysToClear = "";
		var objIds      = "";
		var objId       = "";

		if ( StructKeyExists( cacheMaps, arguments.objectName ) ) {
			keysToClear = StructKeyList( cacheMaps[ arguments.objectName ].__complexFilter );

			if ( IsStruct( arguments.filter ) and StructKeyExists( arguments.filter, "id" ) ) {
				objIds = arguments.filter.id;
			} elseif ( StructKeyExists( arguments.filterParams, "id" ) ) {
				objIds = arguments.filterParams.id;
			}

			if ( IsSimpleValue( objIds ) ) {
				objIds = ListToArray( objIds );
			}

			if ( IsArray( objIds ) and ArrayLen( objIds ) ) {
				for( objId in objIds ){
					if ( StructKeyExists( cacheMaps[ arguments.objectName ], objId ) ) {
						keysToClear = ListAppend( keysToClear, StructKeyList( cacheMaps[ arguments.objectName ][ objId ] ) );
						StructDelete( cacheMaps[ arguments.objectName ], objId );
					}
				}
				StructClear( cacheMaps[ arguments.objectName ].__complexFilter );
			} elseif ( arguments.clearSingleRecordCaches ) {
				for( objId in cacheMaps[ arguments.objectName ] ) {
					if ( objId neq "__complexFilter" ) {
						keysToClear = ListAppend( keysToClear, StructKeyList( cacheMaps[ arguments.objectName ][ objId ] ) );
					}
				}
				StructDelete( cacheMaps, arguments.objectName );
			}

			if ( ListLen( keysToClear ) ) {
				_getDefaultQueryCache().clearMulti( keysToClear );
			}
		}
	}

// SIMPLE PRIVATE PROXIES
	private any function _getAdapter() output=false {
		return _getAdapterFactory().getAdapter( argumentCollection = arguments );
	}

	private any function _runSql() output=false {
		return _getSqlRunner().runSql( argumentCollection = arguments );
	}

// GETTERS AND SETTERS
	private array function _getObjectDirectories() output=false {
		return _objectDirectories;
	}
	private void function _setObjectDirectories( required array objectDirectories ) output=false {
		_objectDirectories = arguments.objectDirectories;
	}

	private any function _getObjectReader() output=false {
		return _objectReader;
	}
	private void function _setObjectReader( required any objectReader ) output=false {
		_objectReader = arguments.objectReader;
	}

	private any function _getSqlSchemaSynchronizer() output=false {
		return _sqlSchemaSynchronizer;
	}
	private void function _setSqlSchemaSynchronizer( required any sqlSchemaSynchronizer ) output=false {
		_sqlSchemaSynchronizer = arguments.sqlSchemaSynchronizer;
	}

	private any function _getAdapterFactory() output=false {
		return _adapterFactory;
	}
	private void function _setAdapterFactory( required any adapterFactory ) output=false {
		_adapterFactory = arguments.adapterFactory;
	}

	private any function _getSqlRunner() output=false {
		return _sqlRunner;
	}
	private void function _setSqlRunner( required any sqlRunner ) output=false {
		_sqlRunner = arguments.sqlRunner;
	}

	private any function _getRelationshipGuidance() output=false {
		return _relationshipGuidance;
	}
	private void function _setRelationshipGuidance( required any relationshipGuidance ) output=false {
		_relationshipGuidance = arguments.relationshipGuidance;
	}

	private any function _getVersioningService() output=false {
		return _versioningService;
	}
	private void function _setVersioningService( required any versioningService ) output=false {
		_versioningService = arguments.versioningService;
	}

	private any function _getPresideObjectDecorator() output=false {
		return _presideObjectDecorator;
	}
	private void function _setPresideObjectDecorator( required any presideObjectDecorator ) output=false {
		_presideObjectDecorator = arguments.presideObjectDecorator;
	}

	private any function _getObjectCache() output=false {
		return _objectCache;
	}
	private void function _setObjectCache( required any objectCache ) output=false {
		_objectCache = arguments.objectCache;
	}

	private any function _getDefaultQueryCache() output=false {
		return _defaultQueryCache;
	}
	private void function _setDefaultQueryCache( required any defaultQueryCache ) output=false {
		_defaultQueryCache = arguments.defaultQueryCache;
	}

	private struct function _getCacheMaps() output=false {
		return _cacheMaps;
	}
	private void function _setCacheMaps( required struct cacheMaps ) output=false {
		_cacheMaps = arguments.cacheMaps;
	}
}