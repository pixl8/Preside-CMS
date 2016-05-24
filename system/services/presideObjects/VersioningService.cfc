component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @presideObjectService.inject PresideObjectService
	 * @coldboxController.inject    coldbox
	 */
	public any function init( required any presideObjectService, required any coldboxController ) output=false {
		_setPresideObjectService( arguments.presideObjectService );
		_setColdboxController( arguments.coldboxController );

		return this;
	}

// PUBLIC API METHODS
	public void function setupVersioningForVersionedObjects( required struct objects, required string primaryDsn ) output=false {
		var versionedObjects = {};

		for( var objectName in objects ){
			var obj = objects[ objectName ];

			if ( IsBoolean( obj.meta.versioned ?: "" ) && obj.meta.versioned ) {
				var versionObjectName = "vrsn_" & objectName;
				var objMeta = duplicate( obj.meta );

				obj.meta.versionObjectName = versionObjectName;

				objMeta.versioned = false;
				objMeta.tableName = "_version_" & objMeta.tableName;

				_removeUniqueIndexes( objMeta );
				_removeRelationships( objMeta );
				_addAdditionalVersioningPropertiesToVersionObject( objMeta, versionObjectName );

				versionedObjects[ versionObjectName ] = { meta = objMeta, instance="auto_created" };
			}
		}

		StructAppend( objects, versionedObjects );

		if ( StructCount( versionedObjects ) ) {
			objects[ "version_number_sequence" ] = _createVersionNumberSequenceObject( primaryDsn );
		}

	}

	public numeric function getNextVersionNumber() output=false {
		return _getPresideObjectService().insertData( objectName="version_number_sequence", data={} );
	}

	public numeric function saveVersionForInsert(
		  required string  objectName
		, required struct  data
		, required struct  manyToManyData
		,          string  versionAuthor = _getLoggedInUserId()
		,          numeric versionNumber = getNextVersionNumber()
	) output=false {
		return saveVersion(
			  objectName        = arguments.objectName
			, data              = arguments.data
			, versionNumber     = arguments.versionNumber
			, versionAuthor     = arguments.versionAuthor
			, manyToManyData    = arguments.manyToManyData
			, changedFields     = StructKeyArray( arguments.data )
		);
	}

	public numeric function saveVersionForUpdate(
		  required string  objectName
		,          string  id
		, required any     filter
		, required struct  filterParams
		, required struct  data
		, required struct  manyToManyData
		,          numeric versionNumber = getNextVersionNumber()
		,          boolean forceVersionCreation = false
		,          string  versionAuthor = _getLoggedInUserId()
	) output=false {
		var poService              = _getPresideObjectService();
		var existingRecords        = poService.selectData( objectName = arguments.objectName, id=( arguments.id ?: NullValue() ), filter=arguments.filter, filterParams=arguments.filterParams );
		var newData                = Duplicate( arguments.data );

		StructDelete( newData, "datecreated" );
		StructDelete( newData, "datemodified" );

		for( var oldData in existingRecords ) {
			var versionedManyToManyFields = _getVersionedManyToManyFieldsForObject( arguments.objectName );
			var oldManyToManyData = versionedManyToManyFields.len() ? poService.getDeNormalizedManyToManyData(
				  objectName   = arguments.objectName
				, id           = oldData.id
				, selectFields = versionedManyToManyFields
			) : {};
			var newDataForChangedFieldsCheck = Duplicate( arguments.data );

			newDataForChangedFieldsCheck.append( arguments.manyToManyData );
			var changedFields = getChangedFields(
				  objectName             = arguments.objectName
				, recordId               = oldData.id
				, newData                = newDataForChangedFieldsCheck
				, existingData           = oldData
				, existingManyToManyData = oldManyToManyData
			);
			var dataChanged = changedFields.len();

			if ( !arguments.forceVersionCreation && !dataChanged ) {
				continue;
			}

			var mergedData  = Duplicate( oldData );
			var mergedManyToManyData = oldManyToManyData;

			StructDelete( mergedData, "datecreated" );
			StructDelete( mergedData, "datemodified" );
			StructAppend( mergedData, arguments.data );
			StructAppend( mergedManyToManyData, arguments.manyToManyData );

			saveVersion(
				  objectName     = arguments.objectName
				, data           = mergedData
				, versionNumber  = arguments.versionNumber
				, versionAuthor  = arguments.versionAuthor
				, manyToManyData = mergedManyToManyData
				, changedFields  = changedFields
			);
		}

		return arguments.versionNumber;
	}

	public numeric function saveVersion(
		  required string  objectName
		, required struct  data
		, required struct  manyToManyData
		, required array   changedFields
		,          numeric versionNumber = getNextVersionNumber()
		,          string  versionAuthor = _getLoggedInUserId()
	) output=false {
		var poService         = _getPresideObjectService();
		var versionObjectName = poService.getVersionObjectName( arguments.objectName );
		var versionedData     = Duplicate( arguments.data );
		var recordId          = versionedData.id ?: "";

		versionedData._version_number         = arguments.versionNumber;
		versionedData._version_author         = arguments.versionAuthor;
		versionedData._version_changed_fields = ',' & arguments.changedFields.toList() & ",";

		if ( poService.fieldExists( versionObjectName, "id" ) ) {
			versionedData.id = versionedData.id ?: NullValue();
		}

		poService.insertData(
			  objectName              = versionObjectName
			, data                    = versionedData
			, insertManyToManyRecords = false
			, useVersioning           = false
		);

		for( var propertyName in manyToManyData ){
			_saveManyToManyVersion(
				  sourceObjectName = arguments.objectName
				, sourceObjectId   = recordId
				, joinPropertyName = propertyName
				, values           = manyToManyData[ propertyName ]
				, versionNumber    = arguments.versionNumber
				, versionAuthor    = arguments.versionAuthor
			);
		}

		return arguments.versionNumber;
	}

	public array function getChangedFields( required string objectName, required string recordId, required struct newData, struct existingData, struct existingManyToManyData ) {
		var poService            = _getPresideObjectService();
		var changedFields        = [];
		var oldData              = arguments.existingData ?: NullValue();
		var oldManyToManyData    = arguments.existingManyToManyData ?: NullValue();
		var properties           = poService.getObjectProperties( arguments.objectName );
		var ignoredFields        = _getIgnoredFieldsForVersioning( arguments.objectName );

		if ( IsNull( oldManyToMay ) ) {
			oldManyToManyData = poService.getDeNormalizedManyToManyData(
				  objectName = arguments.objectName
				, id         = arguments.recordId
			);
		}
		if ( IsNull( oldData ) ) {
			oldData = poService.selectData( objectName = arguments.objectName, id=arguments.recordId );
			for( var d in oldData ) { oldData = d; } // query to struct hack
		}

		for( var field in arguments.newData ) {
			if ( ignoredFields.findNoCase( field ) || !properties.keyExists( field ) ) {
				continue;
			}

			var isManyToManyField = ( properties[ field ].relationship ?: "" ) == "many-to-many";
			if ( isManyToManyField ) {
				if ( StructKeyExists( oldManyToManyData, field ) && oldManyToManyData[ field ] != arguments.newData[ field ] ) {
					changedFields.append( field );
				}
			} else {
				var propDbType = ( properties[ field ].dbtype ?: "" );
				if ( IsEmpty( arguments.newData[ field ] ?: "" ) ) {
					if ( propDbType == "boolean" ) {
						arguments.newData[ field ] = 0;
					}
				}
				if ( StructKeyExists( oldData, field ) && oldData[ field ] != ( arguments.newData[ field ] ?: "" ) ) {
					changedFields.append( field );
				}
			}
		}

		return changedFields;
	}

	public boolean function dataHasChanged() {
		return getChangedFields( argumentCollection=arguments ).len() > 0;
	}

// PRIVATE HELPERS
	private void function _removeUniqueIndexes( required struct objMeta ) output=false {
		for( var ixName in objMeta.indexes ) {
			var ix = objMeta.indexes[ ixName ];
			if ( IsBoolean( ix.unique ?: "" ) && ix.unique ) {
				StructDelete( objMeta.indexes, ixName );
			}
		}
	}

	private void function _removeRelationships( required struct objMeta ) output=false {
		objMeta.relationships = objMeta.relationships ?: {};

		StructClear( objMeta.relationships );
	}

	private void function _addAdditionalVersioningPropertiesToVersionObject( required struct objMeta, required string objectName ) output=false {
		if ( StructKeyExists( objMeta.properties, "id" ) ) {
			if ( ( objMeta.properties.id.generator ?: "" ) == "increment" ) {
				throw( type="VersioningService.pkLimitiation", message="We currently cannot version objects with a an auto incrementing id.", detail="Please either use the default UUID generator for the id or turn versioning off on the object with versioned=false" );
			}
			objMeta.properties.id.pk = false;
		}

		objMeta.properties[ "_version_number" ] = {
			  name         = "_version_number"
			, required     = true
			, type         = "numeric"
			, dbtype       = "int"
			, indexes      = ""
			, control      = "none"
			, maxLength    = 0
			, relationship = "none"
			, relatedto    = "none"
			, generator    = "none"
		};

		objMeta.properties[ "_version_author" ] = {
			  name         = "_version_author"
			, required     = false
			, type         = "string"
			, dbtype       = "varchar"
			, indexes      = ""
			, control      = "none"
			, maxLength    = 100
			, relationship = "none"
			, relatedto    = "none"
			, generator    = "none"
			, renderer     = "adminuser"
		};

		objMeta.properties[ "_version_changed_fields" ] = {
			  name         = "_version_changed_fields"
			, required     = false
			, type         = "string"
			, dbtype       = "text"
			, indexes      = ""
			, control      = "none"
			, maxLength    = 0
			, relationship = "none"
			, relatedto    = "none"
			, generator    = "none"
		};



		objMeta.dbFieldList = ListAppend( objMeta.dbFieldList, "_version_number,_version_author,_version_changed_fields" );

		objMeta.indexes = objMeta.indexes ?: {};
		for(indexKey in objMeta.indexes){
			objMeta.indexes[ _renameTableIndexes(indexKey) ] = duplicate( objMeta.indexes[indexKey]);
			structDelete(objMeta.indexes, indexKey);
		}
		objMeta.indexes[ "ix#_removeTablePrefix(objMeta.tableName)#_version_number" ] = { unique=false, fields="_version_number" };
		objMeta.indexes[ "ix#_removeTablePrefix(objMeta.tableName)#_version_author" ] = { unique=false, fields="_version_author" };
		if ( StructKeyExists( objMeta.properties, "id" ) ) {
			objMeta.indexes[ "ix#_removeTablePrefix(objMeta.tableName)#_record_id" ]      = { unique=false, fields="id,_version_number" };
		}
	}

	private any function _renameTableIndexes( required string indexKey ) output=false {
		return _removeTablePrefix( RereplaceNoCase( arguments.indexKey, '^([iu]x_)', '\1version_' ) );
	}

	private any function _removeTablePrefix( required string indexKey ) output=false {
		return replaceNoCase( arguments.indexKey, '_psys_', '_' );
	}

	private any function _createVersionNumberSequenceObject( required string primaryDsn ) output=false {
		return { instance="auto_created", meta={
			  dbFieldList = "id,datecreated"
			, dsn         = primaryDsn
			, indexes     = {}
			, name        = "version_number_sequence"
			, tableName   = "_version_number_sequence"
			, tablePrefix = "_"
			, versioned   = false
			, properties  = {
				  id            = { name="id"         , type="numeric", dbtype="int"      , control="none", maxLength=0, generator="increment", relationship="none", relatedTo="none", required=true, pk=true }
				, datecreated   = { name="datecreated", type="date"   , dbtype="timestamp", control="none", maxLength=0, generator="none"     , relationship="none", relatedto="none", required=true }
			}
		} };
	}

	private void function _saveManyToManyVersion(
		  required string  sourceObjectName
		, required string  sourceObjectId
		, required string  joinPropertyName
		, required string  values
		, required numeric versionNumber
		, required string  versionAuthor
	) output=false {
		var poService      = _getPresideObjectService();
		var prop           = poService.getObjectProperty( arguments.sourceObjectName, arguments.joinPropertyName );
		var targetObject   = prop.relatedTo ?: "";
		var pivotTable     = prop.relatedVia ?: "";
		var sourceFk       = prop.relationshipIsSource ? prop.relatedViaSourceFk : prop.relatedViaTargetFk;
		var targetFk       = prop.relationshipIsSource ? prop.relatedViaTargetFk : prop.relatedViaSourceFk;
		var versionedPivot = poService.getVersionObjectName( pivotTable );

		if ( Len( Trim( versionedPivot ) ) and Len( Trim( targetObject ) ) ) {
			transaction {
				var recordsToInsert = ListToArray( arguments.values );

				for( var targetId in recordsToInsert ) {
					poService.insertData(
						  objectName = versionedPivot
						, data       = {
							  "#sourceFk#"    = arguments.sourceObjectId
							, "#targetFk#"    = targetId
							, _version_number = arguments.versionNumber
							, _version_author = arguments.versionAuthor
						}
					);
				}
			}
		}
	}

	private string function _getLoggedInUserId() output=false {
		var event = _getColdboxController().getRequestContext();

		return event.isAdminUser() ? event.getAdminUserId() : "";
	}

	private array function _getIgnoredFieldsForVersioning( required string objectName ) {
		var ignoredFields = [ "datemodified" ];
		var properties    = _getPresideObjectService().getObjectProperties( arguments.objectName );

		for( var propertyName in properties ) {
			var ignore = ( properties[ propertyName ].ignoreChangesForVersioning ?: false );

			if ( IsBoolean( ignore ) && ignore ) {
				ignoredFields.append( propertyName );
			}
		}

		return ignoredFields;
	}

	private array function _getVersionedManyToManyFieldsForObject( required string objectName ) {
		var poService       = _getPresideObjectService();
		var properties      = poService.getObjectProperties( arguments.objectName );
		var versionedFields = [];

		for( var propertyName in properties ) {
			if ( poService.isManyToManyProperty( arguments.objectName, propertyName ) ) {
				var relatedVia         = properties[ propertyName ].relatedVia ?: "";
				var versionedByDefault = IsEmpty( relatedVia ) || poService.objectIsAutoGenerated( relatedVia );
				var useVersioning      = properties[ propertyName ].versioned ?: versionedByDefault;

				if ( IsBoolean( useVersioning ) && useVersioning ) {
					versionedFields.append( propertyName );
				}
			}
		}

		return versionedFields;
	}

// GETTERS AND SETTERS
	private any function _getPresideObjectService() output=false {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) output=false {
		_presideObjectService = arguments.presideObjectService;
	}

	private any function _getColdboxController() output=false {
		return _coldboxController;
	}
	private void function _setColdboxController( required any coldboxController ) output=false {
		_coldboxController = arguments.coldboxController;
	}
}