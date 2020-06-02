/**
 * @singleton
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @dsn.inject                coldbox:setting:dsn
	 * @tablePrefix.inject        coldbox:setting:presideObjectsTablePrefix
	 * @interceptorService.inject coldbox:InterceptorService
	 * @featureService.inject     featureService
	 * @adapterFactory.inject     adapterFactory
	 */
	public any function init( required string dsn, required string tablePrefix, required any interceptorService, required any featureService, required any adapterFactory ) {
		_setDsn( arguments.dsn );
		_setTablePrefix( arguments.tablePrefix );
		_setInterceptorService( arguments.interceptorService );
		_setFeatureService( arguments.featureService );
		_setDbAdapter( arguments.adapterFactory.getAdapter( arguments.dsn ) );

		return this;
	}


// PUBLIC API METHODS
	public struct function readObjects( required array objectPaths ) {
		var objects = {};

		for( var objPath in arguments.objectPaths ){
			_announceInterception( state="preLoadPresideObject", interceptData={ objectPath=objPath } );

			var objName = ListLast( objPath, "/" );

			if( !isValid( "regex", objName, "[a-zA-Z_][a-zA-Z0-9_]*" ) ) {
				throw( type="PresideObjectService.invalidObjectName", message="The filename, [#objName#], is not a valid preside object filename. Filenames should start with either a letter or underscrore (_) and contain only letters, underscores and numbers" );
			}

			var obj     = {};

			obj.instance = CreateObject( "component", objPath );
			obj.meta     = readObject( obj.instance );

			objects[ objName ] = objects[ objName ] ?: [];
			objects[ objName ].append( obj );

			_announceInterception( state="postLoadPresideObject", interceptData={ objectName=objName, object=obj } );
		}

		objects = _mergeObjects( objects );
		_removeObjectsUsedInDisabledFeatures( objects );

		_announceInterception( state="postReadPresideObjects", interceptData={ objects=objects } );

		return objects;
	}

	public struct function readObject( required any object ) {
		_announceInterception( state="preReadPresideObject", interceptData={ object=object } );

		var meta          = _mergeExtendedObjectMeta( getMetaData( arguments.object ) );
		var componentName = ListLast( meta.name, "." );
		var key           = "";

		meta.properties    = meta.properties ?: StructNew();
		meta.propertyNames = meta.propertyNames ?: [];


		return meta;
	}

	public void function finalizeMergedObject( required any object ) {
		var meta = arguments.object.meta = arguments.object.meta ?: {};
		var componentName = ListLast( meta.name, "." );

		_announceInterception( state="postReadPresideObject", interceptData={ objectMeta=meta } );

		meta.tablePrefix   = meta.tablePrefix   ?: _getTablePrefix();
		meta.tableName     = meta.tableName     ?: componentName;
		meta.versioned     = meta.versioned     ?: true;
		meta.dsn           = meta.dsn           ?: _getDsn();
		meta.propertyNames = meta.propertyNames ?: [];
		meta.properties    = meta.properties    ?: {};

		_defineIdField( meta );
		_defineCreatedField( meta );
		_defineModifiedField( meta );
		_defineLabelField( meta );
		_addDefaultsToProperties( meta );
		_mergeSystemPropertyDefaults( meta );
		_deletePropertiesMarkedForDeletionOrBelongingToDisabledFeatures( meta );
		_fixOrderOfProperties( meta );


		meta.dbFieldList      = _calculateDbFieldList( meta.properties );
		meta.formulaFieldList = _calculateFormulaFieldList( meta.properties );
		meta.tableName        = LCase( meta.tablePrefix & meta.tableName );
		meta.indexes          = _discoverIndexes( meta.properties, componentName );

		_ensureAllPropertiesHaveName( meta.properties );
	}

	public struct function getAutoPivotObjectDefinition( required struct sourceObject, required struct targetObject, required string pivotObjectName, required string sourcePropertyName, required string targetPropertyName ) {
		var tmp = "";
		var autoObject = "";
		var objAName = LCase( ListLast( sourceObject.name, "." ) );
		var objBName = LCase( ListLast( targetObject.name, "." ) );
		var fieldOrder = ( sourcePropertyName < targetPropertyName ) ? "#sourcePropertyName#,#targetPropertyName#" : "#targetPropertyName#,#sourcePropertyName#";
		var sourceObjectIdField = sourceObject.idField ?: "id";
		var sourceObjectPk      = sourceObject.properties[ sourceObjectIdField ];
		var targetObjectIdField = targetObject.idField ?: "id";
		var targetObjectPk      = targetObject.properties[ targetObjectIdField ];

		autoObject = {
			  dbFieldList = "#fieldOrder#,sort_order"
			, dsn         = sourceObject.dsn
			, indexes     = { "ux_#pivotObjectName#" = { unique=true, fields=fieldOrder } }
			, name        = pivotObjectName
			, tableName   = LCase( sourceObject.tablePrefix & pivotObjectName )
			, tablePrefix = sourceObject.tablePrefix
			, versioned   = ( ( sourceObject.versioned ?: false ) || ( targetObject.versioned ?: false ) )
			, properties  = {
				  "#sourcePropertyName#" = { name=sourcePropertyName, control="auto", type=sourceObjectPk.type, dbtype=sourceObjectPk.dbtype, maxLength=sourceObjectPk.maxLength, generator="none", generate="never", relationship="many-to-one", relatedTo=objAName, required=true, onDelete="cascade" }
				, "#targetPropertyName#" = { name=targetPropertyName, control="auto", type=targetObjectPk.type, dbtype=targetObjectPk.dbtype, maxLength=targetObjectPk.maxLength, generator="none", generate="never", relationship="many-to-one", relatedTo=objBName, required=true, onDelete="cascade" }
				, "sort_order"           = { name="sort_order"      , control="auto", type="numeric"          , dbtype="int"                , maxLength=0                       , generator="none", generate="never", relationship="none"                           , required=false }
			  }
		};

		return autoObject;
	}

// PRIVATE HELPERS
	private struct function _mergeObjects( required struct unMergedObjects ) {
		var merged = {};
		var merger = new Merger();

		for( var objName in unMergedObjects ) {
			merged[ objName ] = unMergedObjects[ objName ][ 1 ];

			for( var i=2; i lte unMergedObjects[ objName ].len(); i++ ) {
				merged[ objName ] = new Merger().mergeObjects( merged[ objName ], unMergedObjects[ objName ][ i ] );
			}

			finalizeMergedObject( merged[ objName ] );
		}
		return merged;
	}

	private struct function _mergeExtendedObjectMeta( required struct meta ) {
		var merged = {};
		var prop   = "";
		var systemAttribs = "extends,accessors,displayname,fullname,hashCode,hint,output,path,persistent,properties,remoteAddress,synchronized";

		if ( StructKeyExists( meta, "extends" ) ) {
			merged = _mergeExtendedObjectMeta( meta.extends );
		}

		for( prop in arguments.meta ) {
			if ( IsSimpleValue( arguments.meta[ prop ] ) and not ListFindNoCase( systemAttribs, prop ) ) {
				merged[ prop ] = arguments.meta[ prop ];
			} else if ( prop eq 'properties' and ArrayLen( arguments.meta[ prop ] ) ) {
				_mergeProperties( merged, arguments.meta[ prop ], arguments.meta.path );
			} else if ( prop eq 'functions' and ArrayLen( arguments.meta[ prop ] ) ) {
				_mergeMethods( merged, arguments.meta[ prop ] );
			}
		}

		return merged;
	}

	private void function _mergeProperties( required struct meta, required array properties, required string pathToCfc ) {
		var prop         = "";
		var propName     = "";
		var orderedProps = _getOrderedPropertiesInAHackyWayBecauseLuceeGivesThemInRandomOrder( pathToCfc = arguments.pathToCfc );

		if ( !ArrayLen( orderedProps ) ) {
			for( prop in arguments.properties ) {
				ArrayAppend( orderedProps, prop.name );
			}
		}

		param name="arguments.meta.properties"    default=StructNew();
		param name="arguments.meta.propertyNames" default=ArrayNew(1);

		for( propName in orderedProps ){
			for( prop in arguments.properties ) {
				if ( prop.name == propName ) {
					if ( !StructKeyExists( arguments.meta.properties, prop.name ) ) {
						arguments.meta.properties[ prop.name ] = {};
					}

					arguments.meta.properties[ prop.name ] = _readProperty( prop, arguments.meta.properties[ prop.name ] );

					if ( !arguments.meta.propertyNames.find( prop.name ) ) {
						arguments.meta.propertyNames.append( prop.name );
					}
				}
			}
		}
	}

	private void function _mergeMethods( required struct meta, required array methods ) {
		var method = "";

		if ( not StructKeyExists( arguments.meta, "methods" ) ) {
			arguments.meta.methods = "";
		}

		for( method in arguments.methods ) {
			param name="method.access" default="public";
			if ( method.access neq "private" and not ListFindNoCase( arguments.meta.methods, method.name ) ) {
				arguments.meta.methods = ListAppend( arguments.meta.methods, method.name );
			}
		}
	}

	private struct function _readProperty( required struct property, required struct inheritedProperty ) {
		var prop = Duplicate( arguments.property );

		if ( prop.type == "any" ) {
			prop.delete( "type" );
		}

		StructAppend( prop, inheritedProperty, false );

		return prop;
	}

	private void function _addDefaultsToProperties( required struct meta ) {
		var defaultAttributes = {
			  type         = "string"
			, dbtype       = "varchar"
			, control      = "default"
			, maxLength    = "0"
			, relationship = "none"
			, relatedto    = "none"
			, generator    = "none"
			, required     = "false"
		};
		var dbAdapterSupportsFkIndexes = _getDbAdapter().autoCreatesFkIndexes();
		var corePropertyNames = [];

		if ( !arguments.meta.noId ) {
			corePropertyNames.append( arguments.meta.idField ?: "id" );
		}
		if ( !arguments.meta.noDateCreated ) {
			corePropertyNames.append( "datecreated" );
		}
		if ( !arguments.meta.noDateModified ) {
			corePropertyNames.append( "datemodified" );
		}
		if ( ( arguments.meta.labelField ?: "label" ) == "label" ) {
			corePropertyNames.append( "label" );
		}

		for( var propName in arguments.meta.properties ){
			var prop           = arguments.meta.properties[ propName ];
			var isCoreProperty = corePropertyNames.findNoCase( propName );
			var createFkIndex  = ( prop.createFkIndex ?: !dbAdapterSupportsFkIndexes );

			if ( ( prop.type ?: "" ) == "any" ) {
				StructDelete( prop, "type" );
			}
			if ( !isCoreProperty ) {
				defaultAttributes.generate = ( prop.generator ?: "none" ) == "none" ? "never" : "always";
				StructAppend( prop, defaultAttributes, false );
			}

			if ( StructKeyExists( prop, "relationship" ) && prop.relationship != "none" && ( prop.relatedTo ?: "none" ) == "none" ) {
				prop.relatedTo = propName;
			}

			if ( [ "many-to-many", "one-to-many" ].find( prop.relationship ?: "" ) ) {
				prop.dbtype = "none";
			}

			if ( ( prop.formula ?: "" ).len() ) {
				prop.dbtype = "none";
			}

			if ( ( ( prop.relationship ?: "" ) == "many-to-one" ) && IsBoolean( createFkIndex ) && createFkIndex ) {
				prop.indexes = prop.indexes ?: "";
				if ( !prop.indexes.listFindNoCase( "fk_#propName#" ) ) {
					prop.indexes = prop.indexes.listAppend( "fk_#propName#" );
				}
			}
		}
	}

	private string function _calculateDbFieldList( required struct properties ) {
		var list = [];
		for( var propName in arguments.properties ){
			if ( ( arguments.properties[ propName ].dbtype ?: "" ) != "none" ) {
				list.append( propName );
			}
		}

		return list.toList();
	}

	private string function _calculateFormulaFieldList( required struct properties ) {
		var list = [];
		for( var propName in arguments.properties ){
			if ( len ( arguments.properties[ propName ].formula ?: "" ) ) {
				list.append( propName );
			}
		}

		return list.toList();
	}

	private void function _mergeSystemPropertyDefaults( required struct meta ) {
		param name="arguments.meta.propertyNames" default=ArrayNew(1);

		var labelField        = arguments.meta.labelField        ?: "label";
		var idField           = arguments.meta.idField           ?: "id";
		var dateCreatedField  = arguments.meta.dateCreatedField  ?: "datecreated";
		var dateModifiedField = arguments.meta.dateModifiedField ?: "datemodified";

		var defaults = {
			  id            = { type="string", dbtype="varchar" , control="none"     , maxLength="35" , relationship="none", relatedto="none", generator="UUID", generate="insert", required="true", pk="true" }
			, label         = { type="string", dbtype="varchar" , control="textinput", maxLength="250", relationship="none", relatedto="none", generator="none", generate="never" , required="true" }
			, datecreated   = { type="date"  , dbtype="datetime", control="none"     , maxLength="0"  , relationship="none", relatedto="none", generator="none", generate="never" , required="true", indexes="datecreated" }
			, datemodified  = { type="date"  , dbtype="datetime", control="none"     , maxLength="0"  , relationship="none", relatedto="none", generator="none", generate="never" , required="true", indexes="datemodified" }
		};

		if ( labelField == "label" ) {
			if ( arguments.meta.propertyNames.find( "label" ) ) {
				StructAppend( arguments.meta.properties.label, defaults.label, false );
			} else if ( !arguments.meta.noLabel ) {
				arguments.meta.properties[ "label" ] = defaults[ "label" ];
				ArrayPrepend( arguments.meta.propertyNames, "label" );
			}
		}

		if ( !arguments.meta.noId ) {
			if ( arguments.meta.propertyNames.find( idField ) ) {
				StructAppend( arguments.meta.properties[ idField ], defaults.id, false );
			} else {
				arguments.meta.properties[ idField ] = defaults[ "id" ];
				ArrayPrepend( arguments.meta.propertyNames, idField );
			}
			if ( idField.len() && idField != "id" && !arguments.meta.propertyNames.findNoCase( "id" ) ) {
				arguments.meta.properties[ idField ].aliases = ( arguments.meta.properties[ idField ].aliases ?: "" ).listAppend( "id" );
			}
		}

		if ( !arguments.meta.noDateCreated ) {
			if ( arguments.meta.propertyNames.find( dateCreatedField ) ) {
				StructAppend( arguments.meta.properties[ dateCreatedField ], defaults.dateCreated, false );
			} else {
				arguments.meta.properties[ dateCreatedField ] = defaults[ "dateCreated" ];
				ArrayAppend( arguments.meta.propertyNames, dateCreatedField );
			}
			if ( dateCreatedField.len() && dateCreatedField != "dateCreated" && !arguments.meta.propertyNames.findNoCase( "dateCreated" ) ) {
				arguments.meta.properties[ dateCreatedField ].aliases = ( arguments.meta.properties[ dateCreatedField ].aliases ?: "" ).listAppend( "dateCreated" );
			}
		}

		if ( !arguments.meta.noDateModified ) {
			if ( arguments.meta.propertyNames.find( dateModifiedField ) ) {
				StructAppend( arguments.meta.properties[ dateModifiedField ], defaults.datemodified, false );
			} else {
				arguments.meta.properties[ dateModifiedField ] = defaults[ "datemodified" ];
				ArrayAppend( arguments.meta.propertyNames, dateModifiedField );
			}
			if ( dateModifiedField.len() && dateModifiedField != "dateModified" && !arguments.meta.propertyNames.findNoCase( "dateModified" ) ) {
				arguments.meta.properties[ dateModifiedField ].aliases = ( arguments.meta.properties[ dateModifiedField ].aliases ?: "" ).listAppend( "dateModified" );
			}
		}

	}

	private void function _deletePropertiesMarkedForDeletionOrBelongingToDisabledFeatures( required struct meta ) {
		for( var propertyName in meta.properties ) {
			var prop              = meta.properties[ propertyName ];
			var featureService    = _getFeatureService();
			var markedForDeletion = IsBoolean( prop.deleted ?: "" ) && prop.deleted;
			var inDisabledFeature = Len( Trim( prop.feature ?: "" ) ) && !featureService.isFeatureEnabled( prop.feature );

			if ( markedForDeletion || inDisabledFeature ) {
				meta.properties.delete( propertyName );
				meta.propertyNames.delete( propertyName );
			}
		}
	}

	private struct function _discoverIndexes( required struct properties, required string objectName ) {
		var prop        = "";
		var indexes     = {};
		var propIndexes = "";
		var propIndex   = "";
		var indexName   = "";
		var fieldPos    = "";

		for ( prop in properties ) {
			if ( StructKeyExists( properties[prop], "indexes" ) ) {
				propIndexes = ListToArray( properties[prop].indexes );
				for( propIndex in propIndexes ) {
					indexName = "ix_#LCase( arguments.objectName )#_#ListFirst( propIndex, '|' )#";
					if ( not StructKeyExists( indexes, indexName ) ) {
						indexes[ indexName ] = { unique=false, fields=[] };
					}
					fieldPos = ListLen( propIndex, '|' ) gt 1 ? Val( ListRest( propIndex, '|' ) ) : 1;
					indexes[ indexName ].fields[ fieldPos ] = prop;
				}
			}
			if ( StructKeyExists( properties[prop], "uniqueindexes" ) ) {
				propIndexes = ListToArray( properties[prop].uniqueindexes );
				for( propIndex in propIndexes ) {
					indexName = "ux_#LCase( arguments.objectName )#_#ListFirst( propIndex, '|' )#";
					if ( not StructKeyExists( indexes, indexName ) ) {
						indexes[ indexName ] = { unique=true, fields=[] };
					}
					fieldPos = ListLen( propIndex, '|' ) gt 1 ? Val( ListRest( propIndex, '|' ) ) : 1;
					indexes[ indexName ].fields[ fieldPos ] = prop;
				}
			}
		}

		for( indexName in indexes ){
			indexes[ indexName ].fields = ArrayToList( indexes[ indexName ].fields );
		}

		return indexes;
	}

	private void function _fixOrderOfProperties( required struct meta ) {
		param name="arguments.meta.propertyNames" default=ArrayNew(1);
		param name="arguments.meta.properties"    default=StructNew();

		var propName     = "";
		var orderedProps = StructNew( 'linked' );

		for( propName in arguments.meta.propertyNames ){
			orderedProps[ propName ] = arguments.meta.properties[ propName ];
		}

		arguments.meta.properties = orderedProps;
	}

	private array function _getOrderedPropertiesInAHackyWayBecauseLuceeGivesThemInRandomOrder( required string pathToCfc ) {
		var propFilePath = arguments.pathToCfc.reReplace( "\.cfc$", "$props.json" );

		if ( FileExists( propFilePath ) ) {
			try {
				var props = DeserializeJson( FileRead( propFilePath ) );
				if ( IsArray( props ) ) {
					return props;
				}
			} catch( any e ) {}
		}

		var cfcContent      = FileRead( arguments.pathToCfc );
		var propertyMatches = $reSearch( 'property\s+[^;/>]*name="([a-zA-Z_\$][a-zA-Z0-9_\$]*)"', cfcContent );

		if ( StructKeyExists( propertyMatches, "$1" ) ) {
			return propertyMatches.$1;
		}

		return [];
	}

	private struct function $reSearch( required string regex, required string text ) {
		var final 	= StructNew();
		var pos		= 1;
		var result	= ReFindNoCase( arguments.regex, arguments.text, pos, true );
		var i		= 0;

		while( ArrayLen(result.pos) GT 1 ) {
			for(i=2; i LTE ArrayLen(result.pos); i++){
				if(not StructKeyExists(final, '$#i-1#')){
					final['$#i-1#'] = ArrayNew(1);
				}
				ArrayAppend(final['$#i-1#'], Mid(arguments.text, result.pos[i], result.len[i]));
			}
			pos = result.pos[2] + 1;
			result	= ReFindNoCase( arguments.regex, arguments.text, pos, true );
		} ;

		return final;
	}

	private void function _defineIdField( required struct objectMeta ) {
		if ( IsBoolean ( arguments.objectMeta.noId ?: "" ) && arguments.objectMeta.noId ) {
			arguments.objectMeta.idField = "";
		} else {
			arguments.objectMeta.idField = arguments.objectMeta.idField ?: "id";
		}
		arguments.objectMeta.noId = !Len( Trim( arguments.objectMeta.idField ) );
	}

	private void function _defineCreatedField( required struct objectMeta ) {
		if ( IsBoolean ( arguments.objectMeta.noDateCreated ?: "" ) && arguments.objectMeta.noDateCreated ) {
			arguments.objectMeta.dateCreatedField = arguments.objectMeta.dateCreatedField ?: "";
		} else {
			arguments.objectMeta.dateCreatedField = arguments.objectMeta.dateCreatedField ?: "datecreated";
		}
		arguments.objectMeta.noDateCreated = arguments.objectMeta.noDateCreated ?: arguments.objectMeta.dateCreatedField == "";
		arguments.objectMeta.noDateCreated = IsBoolean ( arguments.objectMeta.noDateCreated ?: "" ) && arguments.objectMeta.noDateCreated;
	}

	private void function _defineModifiedField( required struct objectMeta ) {
		if ( IsBoolean ( arguments.objectMeta.noDateModified ?: "" ) && arguments.objectMeta.noDateModified ) {
			arguments.objectMeta.dateModifiedField = arguments.objectMeta.dateModifiedField ?: "";
		} else {
			arguments.objectMeta.dateModifiedField = arguments.objectMeta.dateModifiedField ?: "datemodified";
		}
		arguments.objectMeta.noDateModified = arguments.objectMeta.noDateModified ?: arguments.objectMeta.dateModifiedField == "";
		arguments.objectMeta.noDateModified = IsBoolean ( arguments.objectMeta.noDateModified ?: "" ) && arguments.objectMeta.noDateModified;
	}

	private void function _defineLabelField( required struct objectMeta ) {
		if ( IsBoolean ( arguments.objectMeta.nolabel ?: "" ) && arguments.objectMeta.nolabel ) {
			arguments.objectMeta.labelfield = arguments.objectMeta.labelfield ?: "";
		} else {
			arguments.objectMeta.labelfield = arguments.objectMeta.labelfield ?: "label";
		}
		arguments.objectMeta.noLabel = arguments.objectMeta.noLabel ?: arguments.objectMeta.labelfield == "";
		arguments.objectMeta.noLabel = IsBoolean ( arguments.objectMeta.nolabel ?: "" ) && arguments.objectMeta.nolabel;
	}

	private void function _removeObjectsUsedInDisabledFeatures( required struct objects ) {
		var featureService = _getFeatureService();

		for( var objectName in arguments.objects ) {
			var meta = arguments.objects[ objectName ].meta;

			if ( Len( Trim( meta.feature ?: "" ) ) && !featureService.isFeatureEnabled( Trim( meta.feature ) ) ) {
				arguments.objects.delete( objectName );
			}
		}
	}

	private any function _announceInterception( required string state, struct interceptData={} ) {
		return _getInterceptorService().processState( argumentCollection=arguments );
	}

	private void function _ensureAllPropertiesHaveName( required struct properties ) {
		for( var propName in arguments.properties ) {
			arguments.properties[ propName ].name = propName;
		}
	}

// GETTERS AND SETTERS
	private string function _getDsn() {
		return _dsn;
	}
	private void function _setDsn( required string dsn ) {
		_dsn = arguments.dsn;
	}

	private string function _getTablePrefix() {
		return _tablePrefix;
	}
	private void function _setTablePrefix( required string tablePrefix ) {
		_tablePrefix = arguments.tablePrefix;
	}

	private any function _getInterceptorService() {
		return _interceptorService;
	}
	private void function _setInterceptorService( required any interceptorService ) {
		_interceptorService = arguments.interceptorService;
	}

	private any function _getFeatureService() {
		return _featureService;
	}
	private void function _setFeatureService( required any featureService ) {
		_featureService = arguments.featureService;
	}

	private any function _getDbAdapter() {
		return _dbAdapter;
	}
	private void function _setDbAdapter( required any dbAdapter ) {
		_dbAdapter = arguments.dbAdapter;
	}
}