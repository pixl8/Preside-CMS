/**
 * Registers per-object custom field value tables and snapshots values onto host version rows.
 *
 * @singleton      true
 * @presideService true
 * @autodoc        true
 * @feature        customFields
 */
component {

	property name="presideObjectService" inject="delayedInjector:presideObjectService";
	property name="sqlRunner"            inject="delayedInjector:sqlRunner";

	public any function init() {
		return this;
	}

	public string function getValueObjectName( required string objectName ) {
		return "_cfv_" & arguments.objectName;
	}

	public string function getValueTableName( required string hostTableName ) {
		return "_cfv_" & LCase( arguments.hostTableName );
	}

	public boolean function valueObjectExists( required string objectName ) {
		return presideObjectService.objectExists( getValueObjectName( arguments.objectName ) );
	}

	public void function addValueObjects( required struct objects ) {
		var objectNames = StructKeyArray( arguments.objects );

		for( var objectName in objectNames ) {
			if ( _isGeneratedValueObjectName( objectName ) || Left( objectName, 5 ) == "vrsn_" ) {
				continue;
			}
			if ( !_objectMetaEnablesCustomFields( arguments.objects[ objectName ].meta ?: {} ) ) {
				continue;
			}

			var valueObjectName = getValueObjectName( objectName );
			if ( StructKeyExists( arguments.objects, valueObjectName ) ) {
				continue;
			}

			arguments.objects[ valueObjectName ] = {
				  meta     = createValueObjectMeta( objectName, arguments.objects[ objectName ].meta )
				, instance = "auto_created"
			};
		}
	}

	public struct function createValueObjectMeta( required string objectName, required struct hostMeta ) {
		var valueObjectName = getValueObjectName( arguments.objectName );
		var hostIdField     = arguments.hostMeta.idField ?: "id";
		var hostPk          = arguments.hostMeta.properties[ hostIdField ] ?: {
			  type      = "string"
			, dbtype    = "varchar"
			, maxLength = 35
		};
		var properties = {
			id = {
				  name         = "id"
				, type         = "numeric"
				, dbtype       = "bigint"
				, control      = "none"
				, maxLength    = 0
				, generator    = "increment"
				, generate     = "insert"
				, relationship = "none"
				, relatedto    = "none"
				, required     = true
				, pk           = true
			}
			, record = {
				  name          = "record"
				, type          = hostPk.type      ?: "string"
				, dbtype        = hostPk.dbtype    ?: "varchar"
				, maxLength     = Val( hostPk.maxLength ?: 35 )
				, control       = "none"
				, generator     = "none"
				, generate      = "never"
				, relationship  = "many-to-one"
				, relatedto     = arguments.objectName
				, required      = true
				, uniqueindexes = "recordfield|1"
				, ondelete      = "cascade"
				, onupdate      = "cascade"
			}
			, field = {
				  name          = "field"
				, type          = "numeric"
				, dbtype        = "bigint"
				, maxLength     = 0
				, control       = "none"
				, generator     = "none"
				, generate      = "never"
				, relationship  = "many-to-one"
				, relatedto     = "custom_field"
				, required      = true
				, uniqueindexes = "recordfield|2"
				, ondelete      = "cascade"
				, onupdate      = "cascade"
			}
			, field_value = {
				  name         = "field_value"
				, type         = "string"
				, dbtype       = "text"
				, control      = "none"
				, maxLength    = 0
				, generator    = "none"
				, relationship = "none"
				, relatedto    = "none"
				, required     = false
			}
			, shorttext_value = {
				  name         = "shorttext_value"
				, type         = "string"
				, dbtype       = "varchar"
				, control      = "none"
				, maxLength    = 255
				, generator    = "none"
				, relationship = "none"
				, relatedto    = "none"
				, required     = false
				, indexes      = "shorttext"
			}
			, date_value = {
				  name         = "date_value"
				, type         = "date"
				, dbtype       = "datetime"
				, control      = "none"
				, maxLength    = 0
				, generator    = "none"
				, relationship = "none"
				, relatedto    = "none"
				, required     = false
				, indexes      = "datevalue"
			}
			, boolean_value = {
				  name         = "boolean_value"
				, type         = "boolean"
				, dbtype       = "boolean"
				, control      = "none"
				, maxLength    = 0
				, generator    = "none"
				, relationship = "none"
				, relatedto    = "none"
				, required     = false
				, indexes      = "boolvalue"
			}
			, int_value = {
				  name         = "int_value"
				, type         = "numeric"
				, dbtype       = "int"
				, control      = "none"
				, maxLength    = 0
				, generator    = "none"
				, relationship = "none"
				, relatedto    = "none"
				, required     = false
				, indexes      = "intvalue"
			}
			, float_value = {
				  name         = "float_value"
				, type         = "numeric"
				, dbtype       = "float"
				, control      = "none"
				, maxLength    = 0
				, generator    = "none"
				, relationship = "none"
				, relatedto    = "none"
				, required     = false
				, indexes      = "floatvalue"
			}
			, datecreated = {
				  name         = "datecreated"
				, type         = "date"
				, dbtype       = "datetime"
				, control      = "none"
				, maxLength    = 0
				, generator    = "none"
				, relationship = "none"
				, relatedto    = "none"
				, required     = true
				, indexes      = "datecreated"
			}
			, datemodified = {
				  name         = "datemodified"
				, type         = "date"
				, dbtype       = "datetime"
				, control      = "none"
				, maxLength    = 0
				, generator    = "none"
				, relationship = "none"
				, relatedto    = "none"
				, required     = true
				, indexes      = "datemodified"
			}
		};
		var propertyNames = [
			  "id"
			, "record"
			, "field"
			, "field_value"
			, "shorttext_value"
			, "date_value"
			, "boolean_value"
			, "int_value"
			, "float_value"
			, "datecreated"
			, "datemodified"
		];

		return {
			  name                 = valueObjectName
			, tableName            = getValueTableName( arguments.hostMeta.tableName ?: arguments.objectName )
			, tablePrefix          = arguments.hostMeta.tablePrefix ?: ""
			, dsn                  = arguments.hostMeta.dsn         ?: ""
			, versioned            = false
			, useDrafts            = false
			, datamanagerEnabled   = false
			, noLabel              = true
			, siteFiltered         = false
			, tenant               = ""
			, derivedFrom          = arguments.objectName
			, feature              = "customFields"
			, idField              = "id"
			, dateCreatedField     = "datecreated"
			, dateModifiedField    = "datemodified"
			, properties           = properties
			, propertyNames        = propertyNames
			, dbFieldList          = ArrayToList( propertyNames )
			, formulaFieldList     = ""
			, indexes              = {
				  "ux_#valueObjectName#_recordfield" = { unique=true , fields="record,field" }
				, "ix_#valueObjectName#_shorttext"   = { unique=false, fields="shorttext_value" }
				, "ix_#valueObjectName#_datevalue"   = { unique=false, fields="date_value" }
				, "ix_#valueObjectName#_boolvalue"   = { unique=false, fields="boolean_value" }
				, "ix_#valueObjectName#_intvalue"    = { unique=false, fields="int_value" }
				, "ix_#valueObjectName#_floatvalue"  = { unique=false, fields="float_value" }
				, "ix_#valueObjectName#_datecreated"  = { unique=false, fields="datecreated" }
				, "ix_#valueObjectName#_datemodified" = { unique=false, fields="datemodified" }
			  }
		};
	}

	public void function decorateHostVersionObjects( required struct objects ) {
		for( var objectName in arguments.objects ) {
			var meta = arguments.objects[ objectName ].meta ?: {};
			if ( !_objectMetaEnablesCustomFields( meta ) || !$helpers.isTrue( meta.versioned ?: "" ) ) {
				continue;
			}

			var versionObjectName = meta.versionObjectName ?: "";
			if ( !Len( versionObjectName ) || !StructKeyExists( arguments.objects, versionObjectName ) ) {
				continue;
			}

			_addVersionCustomFieldsProperty( arguments.objects[ versionObjectName ].meta );
		}
	}

	public void function snapshotValuesOntoLatestVersion(
		  required string objectName
		, required string recordId
		, required struct values
	) {
		if ( !Len( Trim( arguments.recordId ) ) || !presideObjectService.objectIsVersioned( arguments.objectName ) ) {
			return;
		}

		var versionObjectName = presideObjectService.getVersionObjectName( arguments.objectName );
		if ( !Len( versionObjectName ) || !presideObjectService.objectExists( versionObjectName ) ) {
			return;
		}

		var idField = presideObjectService.getIdField( arguments.objectName );
		var blob    = SerializeJson( arguments.values );
		var latest  = presideObjectService.selectData(
			  objectName   = versionObjectName
			, filter       = { "#idField#"=arguments.recordId, _version_is_latest=true }
			, selectFields = [ "_version_custom_fields", "_version_changed_fields" ]
			, useCache     = false
		);

		if ( !latest.recordCount ) {
			return;
		}

		var data = { _version_custom_fields=blob };
		if ( ToString( latest._version_custom_fields ?: "" ) != blob ) {
			var changedFields = ListToArray( latest._version_changed_fields ?: "" );
			if ( !ArrayFindNoCase( changedFields, "_version_custom_fields" ) ) {
				ArrayAppend( changedFields, "_version_custom_fields" );
			}
			data._version_changed_fields = "," & ArrayToList( changedFields ) & ",";
		}

		presideObjectService.updateData(
			  objectName              = versionObjectName
			, data                    = data
			, filter                  = { "#idField#"=arguments.recordId, _version_is_latest=true }
			, useVersioning           = false
			, skipTrivialInterceptors = true
			, setDateModified         = false
		);
	}

	public struct function getValuesFromVersion(
		  required string  objectName
		, required string  recordId
		, required numeric versionNumber
	) {
		if ( !presideObjectService.objectIsVersioned( arguments.objectName ) || !Val( arguments.versionNumber ) ) {
			return {};
		}

		var versionObjectName = presideObjectService.getVersionObjectName( arguments.objectName );
		if ( !Len( versionObjectName ) || !presideObjectService.objectExists( versionObjectName ) ) {
			return {};
		}

		var idField = presideObjectService.getIdField( arguments.objectName );
		var record  = presideObjectService.selectData(
			  objectName   = versionObjectName
			, filter       = { "#idField#"=arguments.recordId, _version_number=arguments.versionNumber }
			, selectFields = [ "_version_custom_fields" ]
			, useCache     = false
		);

		if ( !record.recordCount || !Len( Trim( record._version_custom_fields ) ) ) {
			return {};
		}

		try {
			var values = DeserializeJson( record._version_custom_fields );
			return IsStruct( values ) ? values : {};
		} catch ( any e ) {
			return {};
		}
	}

	public void function forceHostVersion( required string objectName, required string recordId ) {
		if ( !presideObjectService.objectIsVersioned( arguments.objectName ) || !Len( Trim( arguments.recordId ) ) ) {
			return;
		}

		presideObjectService.updateData(
			  objectName           = arguments.objectName
			, id                   = arguments.recordId
			, data                 = {}
			, forceVersionCreation = true
			, setDateModified      = true
		);
	}

	public void function migrateFromSharedTable() {
		renameLegacyValueTables();

		var oldTable = "psys_custom_field_value";

		for( var objectName in presideObjectService.listObjects() ) {
			if ( !valueObjectExists( objectName ) ) {
				continue;
			}
			if ( !$helpers.isTrue( presideObjectService.getObjectAttribute( objectName, "customFieldsEnabled" ) ) ) {
				continue;
			}

			var valueObject = getValueObjectName( objectName );
			var newTable    = presideObjectService.getObjectAttribute( valueObject, "tableName" );
			var dsn         = presideObjectService.getObjectAttribute( valueObject, "dsn" );
			if ( !Len( Trim( dsn ) ) ) {
				dsn = presideObjectService.getObjectAttribute( objectName, "dsn" );
			}
			if ( !Len( Trim( newTable ) ) || !Len( Trim( dsn ) ) || !_tableExists( oldTable, dsn ) || !_tableExists( newTable, dsn ) ) {
				continue;
			}

			try {
				sqlRunner.runSql(
					  sql    = "
						insert into #newTable# (
							  record
							, field
							, field_value
							, shorttext_value
							, date_value
							, boolean_value
							, int_value
							, float_value
							, datecreated
							, datemodified
						)
						select
							  record_id
							, field
							, field_value
							, shorttext_value
							, date_value
							, boolean_value
							, int_value
							, float_value
							, datecreated
							, datemodified
						from #oldTable#
						where target_object = :target_object
						and not exists (
							select 1
							from #newTable# existing
							where existing.record = #oldTable#.record_id
							and   existing.field  = #oldTable#.field
						)
					  "
					, dsn    = dsn
					, params = [ { name="target_object", value=objectName, type="cf_sql_varchar" } ]
				);
			} catch ( any e ) {}
		}
	}

	public void function renameLegacyValueTables() {
		for( var objectName in presideObjectService.listObjects() ) {
			if ( !valueObjectExists( objectName ) ) {
				continue;
			}
			if ( !$helpers.isTrue( presideObjectService.getObjectAttribute( objectName, "customFieldsEnabled" ) ) ) {
				continue;
			}

			var valueObject = getValueObjectName( objectName );
			var newTable    = presideObjectService.getObjectAttribute( valueObject, "tableName" );
			var hostTable   = presideObjectService.getObjectAttribute( objectName, "tableName" );
			var oldTable    = Len( Trim( hostTable ) ) ? ( hostTable & "_cfv" ) : "";
			var dsn         = presideObjectService.getObjectAttribute( valueObject, "dsn" );
			if ( !Len( Trim( dsn ) ) ) {
				dsn = presideObjectService.getObjectAttribute( objectName, "dsn" );
			}
			if ( !Len( Trim( oldTable ) ) || !Len( Trim( newTable ) ) || !Len( Trim( dsn ) ) || oldTable == newTable ) {
				continue;
			}
			if ( !_tableExists( oldTable, dsn ) ) {
				continue;
			}

			try {
				if ( !_tableExists( newTable, dsn ) ) {
					sqlRunner.runSql( sql="rename table #oldTable# to #newTable#", dsn=dsn );
				} else {
					_copyValueRows( sourceTable=oldTable, targetTable=newTable, dsn=dsn );
					sqlRunner.runSql( sql="drop table #oldTable#", dsn=dsn );
				}
			} catch ( any e ) {}
		}
	}

	private void function _addVersionCustomFieldsProperty( required struct versionMeta ) {
		var properties    = arguments.versionMeta.properties    ?: {};
		var propertyNames = arguments.versionMeta.propertyNames ?: [];
		var dbFieldList   = ListToArray( arguments.versionMeta.dbFieldList ?: "" );

		if ( StructKeyExists( properties, "_version_custom_fields" ) ) {
			return;
		}

		properties._version_custom_fields = {
			  name         = "_version_custom_fields"
			, type         = "string"
			, dbtype       = "text"
			, control      = "none"
			, maxLength    = 0
			, generator    = "none"
			, relationship = "none"
			, relatedto    = "none"
			, required     = false
		};

		if ( !IsArray( propertyNames ) ) {
			propertyNames = [];
		}
		ArrayAppend( propertyNames, "_version_custom_fields" );
		if ( !ArrayFindNoCase( dbFieldList, "_version_custom_fields" ) ) {
			ArrayAppend( dbFieldList, "_version_custom_fields" );
		}

		arguments.versionMeta.properties    = properties;
		arguments.versionMeta.propertyNames = propertyNames;
		arguments.versionMeta.dbFieldList   = ArrayToList( dbFieldList );
	}

	private boolean function _isGeneratedValueObjectName( required string objectName ) {
		return Left( arguments.objectName, 5 ) == "_cfv_" || Right( arguments.objectName, 4 ) == "_cfv";
	}

	private boolean function _objectMetaEnablesCustomFields( required struct meta ) {
		return $helpers.isTrue( arguments.meta.customFieldsEnabled ?: "" );
	}

	private void function _copyValueRows( required string sourceTable, required string targetTable, required string dsn ) {
		sqlRunner.runSql(
			  sql = "
				insert into #arguments.targetTable# (
					  id
					, record
					, field
					, field_value
					, shorttext_value
					, date_value
					, boolean_value
					, int_value
					, float_value
					, datecreated
					, datemodified
				)
				select
					  id
					, record
					, field
					, field_value
					, shorttext_value
					, date_value
					, boolean_value
					, int_value
					, float_value
					, datecreated
					, datemodified
				from #arguments.sourceTable#
				where not exists (
					select 1
					from #arguments.targetTable# existing
					where existing.record = #arguments.sourceTable#.record
					and   existing.field  = #arguments.sourceTable#.field
				)
			  "
			, dsn = arguments.dsn
		);
	}

	private boolean function _tableExists( required string tableName, required string dsn ) {
		try {
			sqlRunner.runSql( sql="select 1 from #arguments.tableName# where 1 = 0", dsn=arguments.dsn );
			return true;
		} catch ( any e ) {
			return false;
		}
	}

}
