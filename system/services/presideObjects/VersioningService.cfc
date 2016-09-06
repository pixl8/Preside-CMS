/**
 * @singleton
 * @presideservice
 *
 */

component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public void function setupVersioningForVersionedObjects( required struct objects, required string primaryDsn ) {
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
				_addAdditionalVersioningPropertiesToVersionObject( objMeta, versionObjectName, objectName );
				_addAdditionalVersioningPropertiesToSourceObject( obj.meta, objectName );

				versionedObjects[ versionObjectName ] = { meta = objMeta, instance="auto_created" };
			}
		}

		StructAppend( objects, versionedObjects );

		if ( StructCount( versionedObjects ) ) {
			objects[ "version_number_sequence" ] = _createVersionNumberSequenceObject( primaryDsn );
		}

	}

	public numeric function getNextVersionNumber() {
		return $getPresideObjectService().insertData( objectName="version_number_sequence", data={} );
	}

	public numeric function saveVersionForInsert(
		  required string  objectName
		, required struct  data
		, required struct  manyToManyData
		,          string  versionAuthor = $getAdminLoggedInUserId()
		,          numeric versionNumber = getNextVersionNumber()
		,          boolean isDraft       = false
	) {
		return saveVersion(
			  objectName        = arguments.objectName
			, data              = arguments.data
			, versionNumber     = arguments.versionNumber
			, versionAuthor     = arguments.versionAuthor
			, manyToManyData    = arguments.manyToManyData
			, isDraft           = arguments.isDraft
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
		,          numeric versionNumber        = getNextVersionNumber()
		,          boolean forceVersionCreation = false
		,          string  versionAuthor        = $getAdminLoggedInUserId()
		,          boolean isDraft              = false
	) {
		var poService       = $getPresideObjectService();
		var existingRecords = poService.selectData( objectName = arguments.objectName, id=( arguments.id ?: NullValue() ), filter=arguments.filter, filterParams=arguments.filterParams, allowDraftVersions=true, fromVersionTable=true );
		var newData         = Duplicate( arguments.data );

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
				, isDraft        = arguments.isDraft
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
		,          string  versionAuthor = $getAdminLoggedInUserId()
		,          boolean isDraft       = false
	) {
		var poService         = $getPresideObjectService();
		var versionObjectName = poService.getVersionObjectName( arguments.objectName );
		var versionedData     = Duplicate( arguments.data );
		var recordId          = versionedData.id ?: "";

		versionedData._version_number          = arguments.versionNumber;
		versionedData._version_author          = arguments.versionAuthor;
		versionedData._version_is_draft        = versionedData._version_has_drafts = arguments.isDraft;
		versionedData._version_changed_fields  = ',' & arguments.changedFields.toList() & ",";
		versionedData._version_is_latest       = !arguments.isDraft;
		versionedData._version_is_latest_draft = true;

		if ( poService.fieldExists( versionObjectName, "id" ) ) {
			versionedData.id = versionedData.id ?: NullValue();
		}

		if ( Len( Trim( versionedData.id ?: "" ) ) ) {
			var cleanLatestData = { _version_is_latest_draft=false };
			if ( !arguments.isDraft ) {
				cleanLatestData._version_is_latest = false;
			}

			poService.updateData(
				  objectName              = versionObjectName
				, data                    = cleanLatestData
				, filter                  = { id = versionedData.id }
				, useVersioning           = false
				, skipTrivialInterceptors = true
				, setDateModified         = false
			);
		}

		poService.insertData(
			  objectName              = versionObjectName
			, data                    = versionedData
			, insertManyToManyRecords = false
			, useVersioning           = false
			, skipTrivialInterceptors = true
		);

		for( var propertyName in manyToManyData ){
			var relationship = poService.getObjectPropertyAttribute(
				  objectName    = arguments.objectName
				, propertyName  = propertyName
				, attributeName = "relationship"
			);

			if ( relationship == "many-to-many" ) {
				_saveManyToManyVersion(
					  sourceObjectName = arguments.objectName
					, sourceObjectId   = recordId
					, joinPropertyName = propertyName
					, values           = manyToManyData[ propertyName ]
					, versionNumber    = arguments.versionNumber
					, versionAuthor    = arguments.versionAuthor
				);
			}
		}

		return arguments.versionNumber;
	}

	public array function getChangedFields( required string objectName, required string recordId, required struct newData, struct existingData, struct existingManyToManyData ) {
		var poService            = $getPresideObjectService();
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
			oldData = poService.selectData( objectName = arguments.objectName, id=arguments.recordId, allowDraftVersions=true );
			for( var d in oldData ) { oldData = d; } // query to struct hack
		}

		for( var field in arguments.newData ) {
			if ( ignoredFields.findNoCase( field ) || !properties.keyExists( field ) ) {
				continue;
			}

			var isManyToManyField = ( properties[ field ].relationship ?: "" ) == "many-to-many";
			if ( isManyToManyField ) {
				if ( StructKeyExists( oldManyToManyData, field ) && Compare( oldManyToManyData[ field ], arguments.newData[ field ] ) ) {
					changedFields.append( field );
				}
			} else {
				var propDbType = ( properties[ field ].dbtype ?: "" );
				if ( IsEmpty( arguments.newData[ field ] ?: "" ) ) {
					if ( propDbType == "boolean" ) {
						arguments.newData[ field ] = 0;
					}
				}
				if ( StructKeyExists( oldData, field ) && Compare( oldData[ field ], arguments.newData[ field ] ?: "" ) ) {
					changedFields.append( field );
				}
			}
		}

		return changedFields;
	}

	public boolean function dataHasChanged() {
		return getChangedFields( argumentCollection=arguments ).len() > 0;
	}

	public numeric function getLatestVersionNumber(
		  required string  objectName
		,          string  recordId
		,          any     filter        = ""
		,          struct  filterParams  = {}
		,          boolean publishedOnly = false
	) {
		var versionObjectName = $getPresideObjectService().getVersionObjectName( arguments.objectName );
		var extraFilters      = [];

		if ( arguments.keyExists( "recordId" ) ) {
			arguments.filter = { id = arguments.recordId };
			arguments.filterParams = {};
		}

		if ( arguments.publishedOnly ) {
			extraFilters.append( { filter="_version_is_draft is null or _version_is_draft = 0" } );
		}

		var record            = $getPresideObjectService().selectData(
			  objectName   = versionObjectName
			, selectFields = [ "Max( _version_number ) as version_number" ]
			, filter       = arguments.filter
			, filterParams = arguments.filterParams
			, extraFilters = extraFilters
			, useCache     = false
		);

		return Val( record.version_number ?: "" );
	}

	public array function getDraftChangedFields( required string objectName, required string recordId ) {
		var versionObjectName = $getPresideObjectService().getVersionObjectName( arguments.objectName );
		var latestPublished   = getLatestVersionNumber(
			  objectName    = arguments.objectName
			, recordId      = arguments.recordId
			, publishedOnly = true
		);
		var versionRecords = $getPresideObjectService().selectData(
			  objectName   = versionObjectName
			, selectFields = [ "_version_changed_fields", "_version_is_draft" ]
			, filter       = "id = :id and _version_number > :_version_number"
			, filterParams = { id=arguments.recordId, _version_number=latestPublished }
		);
		var changedFields = {};

		for( var record in versionRecords ) {
			for( var field in ListToArray( record._version_changed_fields ) ) {
				changedFields[ field ] = "";
			}
		}

		changedFields = changedFields.keyArray().sort( "textnocase" );

		return changedFields;
	}

	public boolean function publishLatestDraft( required string objectName, required string recordId ) {
		var changedFields = getDraftChangedFields( argumentCollection=arguments );
		var dataToPublish = {};
		var record        = $getPresideObjectService().selectData(
			  objectName         = arguments.objectName
			, id                 = recordId
			, fromVersionTable   = true
			, allowDraftVersions = true
		);

		if ( record.recordCount ) {
			for( var r in record ) { record = r; }
			for( var field in changedFields ) {
				if ( record.keyExists( field ) ) {
					dataToPublish[ field ] = record[ field ];
				}
			}

			if ( dataToPublish.count() ) {
				return $getPresideObjectService().updateData(
					  objectName           = arguments.objectName
					, id                   = arguments.recordId
					, data                 = dataToPublish
					, isDraft              = false
					, forceVersionCreation = true
				);
			}
		}

		return false;
	}

	public boolean function promoteVersion(
		  required string  objectName
		, required string  recordId
		, required numeric versionNumber
		,          numeric newVersionNumber = getNextVersionNumber()
	) {
		var versionObjectName = $getPresideObjectService().getVersionObjectName( arguments.objectName );
		var versionRecord     = $getPresideObjectService().selectData(
			  objectName = versionObjectName
			, filter     = { id=arguments.recordId, _version_number=arguments.versionNumber }
		);

		if ( versionRecord.recordCount ) {
			for( var v in versionRecord ) { versionRecord = v; }
			versionRecord.delete( "id"           );
			versionRecord.delete( "datemodified" );
			versionRecord.delete( "datecreated"  );

			return $getPresideObjectService().updateData(
				  objectName           = arguments.objectName
				, id                   = arguments.recordId
				, data                 = versionRecord
				, isDraft              = IsBoolean( versionRecord._version_is_draft ) && versionRecord._version_is_draft
				, versionNumber        = arguments.newVersionNumber
				, forceVersionCreation = true
			);
		}

		return false;
	}

// PRIVATE HELPERS
	private void function _removeUniqueIndexes( required struct objMeta ) {
		for( var ixName in objMeta.indexes ) {
			var ix = objMeta.indexes[ ixName ];
			if ( IsBoolean( ix.unique ?: "" ) && ix.unique ) {
				StructDelete( objMeta.indexes, ixName );
			}
		}
	}

	private void function _removeRelationships( required struct objMeta ) {
		objMeta.relationships = objMeta.relationships ?: {};

		StructClear( objMeta.relationships );
	}

	private void function _addAdditionalVersioningPropertiesToVersionObject( required struct objMeta, required string versionedObjectName, required string originalObjectName ) {
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

		objMeta.properties[ "_version_is_draft" ] = {
			  name         = "_version_is_draft"
			, required     = false
			, type         = "boolean"
			, dbtype       = "boolean"
			, indexes      = ""
			, control      = "none"
			, maxLength    = 0
			, relationship = "none"
			, relatedto    = "none"
			, generator    = "none"
			, default      = false
		};

		objMeta.properties[ "_version_has_drafts" ] = {
			  name         = "_version_has_drafts"
			, required     = false
			, type         = "boolean"
			, dbtype       = "boolean"
			, indexes      = ""
			, control      = "none"
			, maxLength    = 0
			, relationship = "none"
			, relatedto    = "none"
			, generator    = "none"
			, default      = false
		};

		objMeta.properties[ "_version_is_latest" ] = {
			  name         = "_version_is_latest"
			, required     = false
			, type         = "boolean"
			, dbtype       = "boolean"
			, indexes      = ""
			, control      = "none"
			, maxLength    = 0
			, relationship = "none"
			, relatedto    = "none"
			, generator    = "none"
			, default      = false
		};

		objMeta.properties[ "_version_is_latest_draft" ] = {
			  name         = "_version_is_latest_draft"
			, required     = false
			, type         = "boolean"
			, dbtype       = "boolean"
			, indexes      = ""
			, control      = "none"
			, maxLength    = 0
			, relationship = "none"
			, relatedto    = "none"
			, generator    = "none"
			, default      = false
		};

		objMeta.dbFieldList = ListAppend( objMeta.dbFieldList, "_version_number,_version_author,_version_changed_fields,_version_is_draft,_version_has_drafts,_version_is_latest,_version_is_latest_draft" );

		objMeta.indexes = objMeta.indexes ?: {};
		for(indexKey in objMeta.indexes){
			objMeta.indexes[ _renameTableIndexes(indexKey, arguments.originalObjectName, arguments.versionedObjectName ) ] = duplicate( objMeta.indexes[indexKey]);
			structDelete(objMeta.indexes, indexKey);
		}
		objMeta.indexes[ "ix_#arguments.versionedObjectName#_version_number" ] = { unique=false, fields="_version_number" };
		objMeta.indexes[ "ix_#arguments.versionedObjectName#_version_author" ] = { unique=false, fields="_version_author" };
		objMeta.indexes[ "ix_#arguments.versionedObjectName#_is_draft"       ] = { unique=false, fields="_version_is_draft" };
		objMeta.indexes[ "ix_#arguments.versionedObjectName#_is_latest"      ] = { unique=false, fields="_version_is_latest" };
		objMeta.indexes[ "ix_#arguments.versionedObjectName#_is_latest_drft" ] = { unique=false, fields="_version_is_latest_draft" };
		if ( StructKeyExists( objMeta.properties, "id" ) ) {
			objMeta.indexes[ "ix_#arguments.versionedObjectName#_record_id" ] = { unique=false, fields="id,_version_number" };
		}
	}

	private void function _addAdditionalVersioningPropertiesToSourceObject( required struct objMeta, required string objectName ) {
		objMeta.properties[ "_version_is_draft" ] = {
			  name         = "_version_is_draft"
			, required     = false
			, type         = "boolean"
			, dbtype       = "boolean"
			, indexes      = ""
			, control      = "none"
			, maxLength    = 0
			, relationship = "none"
			, relatedto    = "none"
			, generator    = "none"
			, default      = false
		};
		objMeta.properties[ "_version_has_drafts" ] = {
			  name         = "_version_has_drafts"
			, required     = false
			, type         = "boolean"
			, dbtype       = "boolean"
			, indexes      = ""
			, control      = "none"
			, maxLength    = 0
			, relationship = "none"
			, relatedto    = "none"
			, generator    = "none"
			, default      = false
		};

		objMeta.dbFieldList = ListAppend( objMeta.dbFieldList, "_version_is_draft,_version_has_drafts" );
		objMeta.indexes[ "ix_#arguments.objectName#_is_draft" ] = { unique=false, fields="_version_is_draft" };
		objMeta.indexes[ "ix_#arguments.objectName#_has_drafts" ] = { unique=false, fields="_version_has_drafts" };
	}

	private any function _renameTableIndexes( required string indexKey, required string objectName, required string versionedObjectName ) {
		return ReplaceNoCase( arguments.indexKey, arguments.objectName, arguments.versionedObjectName );
	}

	private any function _createVersionNumberSequenceObject( required string primaryDsn ) {
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
	) {
		var poService      = $getPresideObjectService();
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

	private array function _getIgnoredFieldsForVersioning( required string objectName ) {
		var ignoredFields = [ "datemodified" ];
		var properties    = $getPresideObjectService().getObjectProperties( arguments.objectName );

		for( var propertyName in properties ) {
			var ignore = ( properties[ propertyName ].ignoreChangesForVersioning ?: false );

			if ( IsBoolean( ignore ) && ignore ) {
				ignoredFields.append( propertyName );
			}
		}

		return ignoredFields;
	}

	private array function _getVersionedManyToManyFieldsForObject( required string objectName ) {
		var poService       = $getPresideObjectService();
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
}