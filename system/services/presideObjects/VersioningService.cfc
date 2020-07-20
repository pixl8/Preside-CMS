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
		, required query   existingRecords
		, required struct  changedData
		,          numeric versionNumber        = getNextVersionNumber()
		,          boolean forceVersionCreation = false
		,          string  versionAuthor        = $getAdminLoggedInUserId()
		,          boolean isDraft              = false
	) {
		var poService         = $getPresideObjectService();
		var idField           = poService.getidField( arguments.objectName );
		var dateCreatedField  = poService.getdateCreatedField( arguments.objectName );
		var dateModifiedField = poService.getdateModifiedField( arguments.objectName );

		for( var oldData in existingRecords ) {
			var versionedManyToManyFields = getVersionedManyToManyFieldsForObject( arguments.objectName );
			var oldManyToManyData = versionedManyToManyFields.len() ? poService.getDeNormalizedManyToManyData(
				  objectName   = arguments.objectName
				, id           = oldData[ idField ]
				, selectFields = versionedManyToManyFields
			) : {};
			var prevVersionsExist = poService.dataExists(
				  objectName         = arguments.objectName
				, id                 = oldData.id
				, fromVersionTable   = true
				, allowDraftVersions = true
			);

			if ( !prevVersionsExist ) {

				saveVersionForInsert(
					  objectName     = arguments.objectName
					, data           = oldData
					, manyToManyData = oldManyToManyData
					, versionNumber  = arguments.versionNumber
					, isDraft        = arguments.isDraft
				);

				arguments.versionNumber = getNextVersionNumber();
			}

			if ( !arguments.forceVersionCreation && !StructKeyExists( arguments.changedData, oldData.id ) ) {
				if ( prevVersionsExist ) {
					updateLatestVersionWithNonVersionedChanges(
						  objectName = arguments.objectName
						, recordId   = oldData.id
						, data       = StructCopy( arguments.data )
					);
				}

				continue;
			}

			var mergedData  = Duplicate( oldData );
			var mergedManyToManyData = oldManyToManyData;

			mergedData.delete( dateCreatedField  );
			mergedData.delete( dateModifiedField );
			if ( dateCreatedField != "datecreated" ) {
				mergedData.delete( "datecreated" );
			}
			if ( dateModifiedField != "datemodified" ) {
				mergedData.delete( "datemodified" );
			}

			mergedData.append( arguments.data );
			mergedManyToManyData.append( arguments.manyToManyData );

			saveVersion(
				  objectName     = arguments.objectName
				, data           = mergedData
				, versionNumber  = arguments.versionNumber
				, versionAuthor  = arguments.versionAuthor
				, manyToManyData = mergedManyToManyData
				, changedFields  = StructKeyArray( arguments.changedData[ oldData.id ] ?: {} )
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
		var idField           = poService.getIdField( arguments.objectName );
		var versionedData     = Duplicate( arguments.data );
		var recordId          = versionedData[ idField ] ?: "";

		versionedData._version_number          = arguments.versionNumber;
		versionedData._version_author          = arguments.versionAuthor;
		versionedData._version_is_draft        = versionedData._version_has_drafts = arguments.isDraft;
		versionedData._version_changed_fields  = ',' & arguments.changedFields.toList() & ",";
		versionedData._version_is_latest       = !arguments.isDraft;
		versionedData._version_is_latest_draft = true;

		if ( poService.fieldExists( versionObjectName, idField ) ) {
			versionedData[ idField ] = versionedData[ idField ] ?: NullValue();
		}

		if ( Len( Trim( versionedData[ idField ] ?: "" ) ) ) {
			var cleanLatestData = { _version_is_latest_draft=false };
			if ( !arguments.isDraft ) {
				cleanLatestData._version_is_latest = false;
			}

			poService.updateData(
				  objectName              = versionObjectName
				, data                    = cleanLatestData
				, filter                  = { "#idField#" = versionedData[ idField ] }
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
			, isDraft                 = arguments.isDraft
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
					, isDraft          = arguments.isDraft
				);
			} else if ( relationship == "one-to-many" && poService.isOneToManyConfiguratorObject( arguments.objectName, propertyName ) ) {
				_saveOneToManyConfiguratorVersion(
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

	public numeric function updateLatestVersionWithNonVersionedChanges(
		  required string objectName
		, required string recordId
		, required struct data
	) {
		var poService         = $getPresideObjectService();
		var versionObjectName = poService.getVersionObjectName( arguments.objectName );
		var idField           = poService.getIdField( arguments.objectName );
		var filter            = "#idField# = :#idField# and ( _version_is_latest = :_version_is_latest or _version_is_latest_draft = :_version_is_latest_draft )"
		var filterParams      = {
			  "#idField#"              = arguments.recordId
			, _version_is_latest       = true
			, _version_is_latest_draft = true
		};

		poService.updateData(
			  objectName              = versionObjectName
			, data                    = arguments.data
			, filter                  = filter
			, filterParams            = filterParams
			, useVersioning           = false
			, skipTrivialInterceptors = true
			, setDateModified         = false
		);
	}

	public array function getChangedFields( required string objectName, required string recordId, required struct newData, struct existingData, struct existingManyToManyData ) {
		var poService         = $getPresideObjectService();
		var changedFields     = [];
		var oldData           = arguments.existingData ?: NullValue();
		var oldManyToManyData = arguments.existingManyToManyData ?: NullValue();
		var properties        = poService.getObjectProperties( arguments.objectName );
		var ignoredFields     = _getIgnoredFieldsForVersioning( arguments.objectName );
		var oldIsTrue         = false;
		var newIsTrue         = false;

		if ( IsNull( local.oldManyToManyData ) ) {
			oldManyToManyData = poService.getDeNormalizedManyToManyData(
				  objectName = arguments.objectName
				, id         = arguments.recordId
			);
		}
		if ( IsNull( local.oldData ) ) {
			oldData = poService.selectData( objectName = arguments.objectName, id=arguments.recordId, allowDraftVersions=true );
			for( var d in oldData ) { oldData = d; } // query to struct hack
		}

		for( var field in arguments.newData ) {
			if ( ignoredFields.findNoCase( field ) || !StructKeyExists( properties, field ) ) {
				continue;
			}

			var isManyToManyField   = ( properties[ field ].relationship ?: "" ) == "many-to-many";
			var isConfiguratorField = poService.isOneToManyConfiguratorObject( arguments.objectName, field );
			if ( isManyToManyField || isConfiguratorField ) {
				if ( StructKeyExists( oldManyToManyData, field ) && Compare( oldManyToManyData[ field ], arguments.newData[ field ] ) ) {
					changedFields.append( field );
				}
			} else {
				if ( !StructKeyExists( oldData, field ) ) {
					continue;
				}

				var propDbType = ( properties[ field ].dbtype ?: "" );

				if ( propDbType == "boolean" && IsBoolean( oldData[ field ] ) ) {
					oldIsTrue = IsBoolean( oldData[ field ] ) && oldData[ field ];
					newIsTrue = IsBoolean( arguments.newData[ field ] ) && arguments.newData[ field ];
					if ( oldIsTrue != newIsTrue ) {
						changedFields.append( field );
					}
				} else if ( ( propDbType == "datetime" || propDbType == "date" ) && isDate( arguments.newData[ field ] ?: "" ) && isDate( oldData[ field ] ) ) {
					if ( dateCompare( oldData[ field ], arguments.newData[ field ] ) ) {
						changedFields.append( field );
					}
				} else if ( propDbType == "varchar" || propDbType == "text" ){
					if ( compare( trim( oldData[ field ] ?: "" ), trim( arguments.newData[ field ] ?: "" ) ) != 0 ){
						changedFields.append( field );
					}
				} else if ( propDbType == "int" || propDbType == "float" ){
					if ( val( oldData[ field ] ?: "" ) != val( arguments.newData[ field ] ?: "" ) ){
						changedFields.append( field );
					}
				} else if ( Compare( oldData[ field ], arguments.newData[ field ] ?: "" ) ) {
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

		if ( StructKeyExists( arguments, "recordId" ) ) {
			arguments.filter = { id = arguments.recordId };
			arguments.filterParams = {};
		}

		if ( arguments.publishedOnly ) {
			extraFilters.append( { filter="_version_is_draft is null or _version_is_draft = '0'" } );
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
		var idField           = $getPresideObjectService().getIdField( arguments.objectName );
		var latestPublished   = getLatestVersionNumber(
			  objectName    = arguments.objectName
			, recordId      = arguments.recordId
			, publishedOnly = true
		);
		var versionRecords = $getPresideObjectService().selectData(
			  objectName   = versionObjectName
			, selectFields = [ "_version_changed_fields", "_version_is_draft" ]
			, filter       = "#idField# = :#idField# and _version_number > :_version_number"
			, filterParams = { "#idField#"=arguments.recordId, _version_number=latestPublished }
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
				if ( StructKeyExists( record, field ) ) {
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
		var idField           = $getPresideObjectService().getIdField( arguments.objectName );
		var dateCreatedField  = $getPresideObjectService().getDateCreatedField( arguments.objectName );
		var dateModifiedField = $getPresideObjectService().getDateModifiedField( arguments.objectName );

		var versionRecord     = $getPresideObjectService().selectData(
			  objectName = versionObjectName
			, filter     = { "#idField#"=arguments.recordId, _version_number=arguments.versionNumber }
		);

		if ( versionRecord.recordCount ) {
			for( var v in versionRecord ) { versionRecord = v; }
			versionRecord.delete( "id"             );
			versionRecord.delete( "datemodified"   );
			versionRecord.delete( "datecreated"    );
			versionRecord.delete( idField          );
			versionRecord.delete( dateCreatedField );
			versionRecord.delete( dateModifiedField );

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
		var idField = objMeta.idField ?: "id";
		if ( StructKeyExists( objMeta.properties, idField ) ) {
			if ( ( objMeta.properties[ idField ].generator ?: "" ) == "increment" && ( objMeta.versionOnInsert ?: true ) ) {
				throw( type="VersioningService.pkLimitiation", message="We currently cannot version objects with an auto incrementing id UNLESS you set @versionOnInsert to false on the object CFC definition.", detail="Please either use the default UUID generator for the id, set versionOnInsert=false or turn versioning off on the object with versioned=false" );
			}
			objMeta.properties[ idField ].pk = false;
			objMeta.properties[ idField ].generator = "none";
			objMeta.properties[ idField ].generate = "never";
		}

		objMeta.properties[ "_version_number" ] = objMeta.properties[ "_version_number" ] ?: {};
		objMeta.properties[ "_version_number" ].append( {
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
		} );

		objMeta.properties[ "_version_author" ] = objMeta.properties[ "_version_author" ] ?: {};
		objMeta.properties[ "_version_author" ].append( {
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
		} );

		objMeta.properties[ "_version_changed_fields" ] = objMeta.properties[ "_version_changed_fields" ] ?: {};
		objMeta.properties[ "_version_changed_fields" ].append( {
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
		} );

		objMeta.properties[ "_version_is_draft" ] = objMeta.properties[ "_version_is_draft" ] ?: {};
		objMeta.properties[ "_version_is_draft" ].append( {
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
		} );

		objMeta.properties[ "_version_has_drafts" ] = objMeta.properties[ "_version_has_drafts" ] ?: {};
		objMeta.properties[ "_version_has_drafts" ].append( {
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
		} );

		objMeta.properties[ "_version_is_latest" ] = objMeta.properties[ "_version_is_latest" ] ?: {};
		objMeta.properties[ "_version_is_latest" ].append( {
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
		} );

		objMeta.properties[ "_version_is_latest_draft" ] = objMeta.properties[ "_version_is_latest_draft" ] ?: {};
		objMeta.properties[ "_version_is_latest_draft" ].append( {
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
		} );

		for( var fieldName in [ "_version_number", "_version_author", "_version_changed_fields", "_version_is_draft", "_version_has_drafts", "_version_is_latest", "_version_is_latest_draft" ] ) {
			if ( !objMeta.dbFieldList.listFindNoCase( fieldName ) ) {
				objMeta.dbFieldList = objMeta.dbFieldList.listAppend( fieldName );
			}
		}

		objMeta.indexes = objMeta.indexes ?: {};
		for( var indexKey in objMeta.indexes ){
			objMeta.indexes[ _renameTableIndexes(indexKey, arguments.originalObjectName, arguments.versionedObjectName ) ] = duplicate( objMeta.indexes[indexKey]);
			structDelete(objMeta.indexes, indexKey);
		}
		objMeta.indexes[ "ix_#arguments.versionedObjectName#_version_number" ] = { unique=false, fields="_version_number" };
		objMeta.indexes[ "ix_#arguments.versionedObjectName#_version_author" ] = { unique=false, fields="_version_author" };
		objMeta.indexes[ "ix_#arguments.versionedObjectName#_is_draft"       ] = { unique=false, fields="_version_is_draft" };
		objMeta.indexes[ "ix_#arguments.versionedObjectName#_is_latest"      ] = { unique=false, fields="_version_is_latest" };
		objMeta.indexes[ "ix_#arguments.versionedObjectName#_is_latest_drft" ] = { unique=false, fields="_version_is_latest_draft" };
		if ( StructKeyExists( objMeta.properties, idField ) ) {
			objMeta.indexes[ "ix_#arguments.versionedObjectName#_record_id" ] = { unique=false, fields="#idField#,_version_number" };
		}
	}

	private void function _addAdditionalVersioningPropertiesToSourceObject( required struct objMeta, required string objectName ) {
		objMeta.properties[ "_version_is_draft" ] = objMeta.properties[ "_version_is_draft" ] ?: {};
		objMeta.properties[ "_version_is_draft" ].append( {
			  name          = "_version_is_draft"
			, required      = false
			, type          = "boolean"
			, dbtype        = "boolean"
			, indexes       = ""
			, control       = "none"
			, maxLength     = 0
			, relationship  = "none"
			, relatedto     = "none"
			, generator     = "none"
			, default       = false
			, adminRenderer = "none"
		} );
		objMeta.properties[ "_version_has_drafts" ] = objMeta.properties[ "_version_has_drafts" ] ?: {};
		objMeta.properties[ "_version_has_drafts" ].append( {
			  name          = "_version_has_drafts"
			, required      = false
			, type          = "boolean"
			, dbtype        = "boolean"
			, indexes       = ""
			, control       = "none"
			, maxLength     = 0
			, relationship  = "none"
			, relatedto     = "none"
			, generator     = "none"
			, default       = false
			, adminRenderer = "none"
		} );

		for( var fieldName in [ "_version_is_draft", "_version_has_drafts" ] ) {
			if ( !objMeta.dbFieldList.listFindNoCase( fieldName ) ) {
				objMeta.dbFieldList = objMeta.dbFieldList.listAppend( fieldName );
			}
		}

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
		,          boolean isDraft = false
	) {
		var poService      = $getPresideObjectService();
		var prop           = poService.getObjectProperty( arguments.sourceObjectName, arguments.joinPropertyName );
		var targetObject   = prop.relatedTo ?: "";
		var pivotTable     = prop.relatedVia ?: "";
		var sourceFk       = prop.relationshipIsSource ? prop.relatedViaSourceFk : prop.relatedViaTargetFk;
		var targetFk       = prop.relationshipIsSource ? prop.relatedViaTargetFk : prop.relatedViaSourceFk;
		var versionedPivot = poService.getVersionObjectName( pivotTable );
		var sortOrder      = 0;

		if ( Len( Trim( versionedPivot ) ) and Len( Trim( targetObject ) ) ) {
			transaction {

			if( arguments.isDraft ){
				poService.updateData(
					  objectName = versionedPivot
					, filter     = { "#sourceFk#"=arguments.sourceObjectId, _version_is_latest_draft=1 }
					, data       = {
						_version_is_latest_draft = 0
					}
				);
			}else{
				poService.updateData(
					  objectName = versionedPivot
					, filter     = { "#sourceFk#"=arguments.sourceObjectId, _version_is_latest=1 }
					, data       = {
						_version_is_latest = 0
					}
				);
			}

				var recordsToInsert = ListToArray( arguments.values );

				for( var targetId in recordsToInsert ) {
					poService.insertData(
						  objectName = versionedPivot
						, data       = {
							  "#sourceFk#"    = arguments.sourceObjectId
							, "#targetFk#"    = targetId
							, sort_order      = ++sortOrder
							, _version_number = arguments.versionNumber
							, _version_author = arguments.versionAuthor
							, _version_is_latest       = !arguments.isDraft
							, _version_is_draft        = arguments.isDraft
							, _version_is_latest_draft = arguments.isDraft
						}
					);
				}
			}
		}
	}

	private void function _saveOneToManyConfiguratorVersion(
		  required string  sourceObjectName
		, required string  sourceObjectId
		, required string  joinPropertyName
		, required string  values
		, required numeric versionNumber
		, required string  versionAuthor
	) {
		var poService       = $getPresideObjectService();
		var prop            = poService.getObjectProperty( arguments.sourceObjectName, arguments.joinPropertyName );
		var targetObject    = prop.relatedTo ?: "";
		var targetFk        = prop.relationshipKey ?: arguments.sourceObjectName;
		var recordsToSave   = deserializeJSON( "[ #values# ]" );
		var versionedTarget = poService.getVersionObjectName( targetObject );
		var sort_order      = 0;

		if ( Len( Trim( versionedTarget ) ) and Len( Trim( targetObject ) ) ) {
			transaction {
				for( var record in recordsToSave ) {
					if ( record.__fromDb ?: false ) {
						record = poService.selectData( objectName=targetObject, id=record.id );
						record = queryRowToStruct( record );
					}

					record[ targetFk ] = sourceObjectId;
					record.sort_order  = ++sort_order;

					if ( len( record.id ?: "" ) ) {
						poService.updateData(
							  objectName              = targetObject
							, id                      = record.id
							, data                    = record
							, updateManyToManyRecords = true
							, forceVersionCreation    = true
							, versionNumber           = arguments.versionNumber
						);
					}
				}
			}
		}
	}

	private boolean function _oneToManyConfiguratorDataChanged( required string sourceObject, required string sourceProperty, required string sourceId, required string newData ) {
		var poService     = $getPresideObjectService();
		var prop          = poService.getObjectProperty( arguments.sourceObject, arguments.sourceProperty );
		var targetFk      = prop.relationshipKey ?: arguments.sourceObject;
		var targetObject  = prop.relatedTo       ?: "";
		var targetIdField = poService.getIdField( targetObject );
		var newDataItems  = len( newData ) ? deserializeJSON( "[ #newData# ]" ) : [];

		var existingRecords  = poService.selectData(
			  objectName       = targetObject
			, filter           = { "#targetFk#"=arguments.sourceId }
			, selectFields     = [ "#targetObject#.#targetIdField# as id" ]
			, useCache         = false
			, recordCountOnly  = true
		);

		if ( existingRecords != newDataItems.len() ) {
			return true;
		}

		for( var item in newDataItems ) {
			if ( !( item.__fromDb ?: false ) ) {
				return true;
			}
		}

		return false;
	}

	private array function _getIgnoredFieldsForVersioning( required string objectName ) {
		var ignoredFields = [ $getPresideObjectService().getDateModifiedField( arguments.objectName ) ];
		var properties    = $getPresideObjectService().getObjectProperties( arguments.objectName );

		for( var propertyName in properties ) {
			var ignore = ( properties[ propertyName ].ignoreChangesForVersioning ?: false );

			if ( IsBoolean( ignore ) && ignore ) {
				ignoredFields.append( propertyName );
			}
		}

		return ignoredFields;
	}

	public array function getVersionedManyToManyFieldsForObject( required string objectName ) {
		var poService       = $getPresideObjectService();
		var properties      = poService.getObjectProperties( arguments.objectName );
		var versionedFields = [];

		for( var propertyName in properties ) {
			if ( poService.isManyToManyProperty( arguments.objectName, propertyName ) || poService.isOneToManyConfiguratorObject( arguments.objectName, propertyName ) ) {
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

	private struct function queryRowToStruct( required query qry, numeric row = 1 ) {
		var strct = StructNew();
		var cols  = ListToArray( arguments.qry.columnList );

		for( var col in cols ){
			strct[col] = arguments.qry[col][arguments.row];
		}

		return strct;
	}
}