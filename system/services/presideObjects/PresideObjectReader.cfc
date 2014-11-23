component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @dsn.inject                coldbox:setting:dsn
	 * @tablePrefix.inject        coldbox:setting:presideObjectsTablePrefix
	 * @interceptorService.inject coldbox:InterceptorService
	 */
	public any function init( required string dsn, required string tablePrefix, required any interceptorService ) output=false {
		_setDsn( arguments.dsn );
		_setTablePrefix( arguments.tablePrefix );
		_setInterceptorService( arguments.interceptorService );

		return this;
	}


// PUBLIC API METHODS
	public struct function readObjects( required array objectPaths ) output=false {
		var objects = {};

		for( var objPath in arguments.objectPaths ){
			_announceInterception( state="preLoadPresideObject", interceptData={ objectPath=objPath } );

			var objName = ListLast( objPath, "/" );
			var obj     = {};

			obj.instance = CreateObject( "component", objPath );
			obj.meta     = readObject( obj.instance );

			objects[ objName ] = objects[ objName ] ?: [];
			objects[ objName ].append( obj );

			_announceInterception( state="postLoadPresideObject", interceptData={ objectName=objName, object=obj } );
		}

		objects = _mergeObjects( objects );

		return objects;
	}

	public struct function readObject( required any object ) output=false {
		_announceInterception( "preReadPresideObject", { object=object } );

		var meta          = _mergeExtendedObjectMeta( getMetaData( arguments.object ) );
		var componentName = ListLast( meta.name, "." );
		var key           = "";

		meta.properties    = meta.properties ?: StructNew();
		meta.propertyNames = meta.propertyNames ?: [];


		return meta;
	}

	public void function finalizeMergedObject( required any object ) output=false {
		var meta = arguments.object.meta = arguments.object.meta ?: {};
		var componentName = ListLast( meta.name, "." );

		_announceInterception( "postReadPresideObject", { objectMeta=meta } );

		meta.tablePrefix   = meta.tablePrefix   ?: _getTablePrefix();
		meta.tableName     = meta.tableName     ?: componentName;
		meta.versioned     = meta.versioned     ?: true;
		meta.dsn           = meta.dsn           ?: _getDsn();
		meta.propertyNames = meta.propertyNames ?: [];
		meta.properties    = meta.properties    ?: {};


		_defineLabelField( meta );
		_addDefaultsToProperties( meta.properties );
		_mergeSystemPropertyDefaults( meta );
		_fixOrderOfProperties( meta );

		meta.dbFieldList = _calculateDbFieldList( meta.properties );
		meta.properties  = _convertPropertiesToBeans( meta.properties );
		meta.tableName   = meta.tablePrefix & meta.tableName;
		meta.indexes     = _discoverIndexes( meta.properties, componentName );
	}

	public struct function getAutoPivotObjectDefinition( required struct sourceObject, required struct targetObject, required string pivotObjectName, required string sourcePropertyName, required string targetPropertyName ) output=false {
		var tmp = "";
		var autoObject = "";
		var objAName = LCase( ListLast( sourceObject.name, "." ) );
		var objBName = LCase( ListLast( targetObject.name, "." ) );
		var fieldOrder = ( sourcePropertyName < targetPropertyName ) ? "#sourcePropertyName#,#targetPropertyName#" : "#targetPropertyName#,#sourcePropertyName#";

		autoObject = {
			  dbFieldList = "#fieldOrder#,sort_order"
			, dsn         = sourceObject.dsn
			, indexes     = { "ux_#pivotObjectName#" = { unique=true, fields="#fieldOrder#" } }
			, name        = pivotObjectName
			, tableName   = sourceObject.tablePrefix & pivotObjectName
			, tablePrefix = sourceObject.tablePrefix
			, versioned   = ( ( sourceObject.versioned ?: false ) || ( targetObject.versioned ?: false ) )
			, properties  = {
				  "#sourcePropertyName#" = new Property( name=sourcePropertyName, control="auto", type=sourceObject.properties.id.type, dbtype=sourceObject.properties.id.dbtype, maxLength=sourceObject.properties.id.maxLength, generator="none", relationship="many-to-one", relatedTo=objAName, required=true, onDelete="cascade" )
				, "#targetPropertyName#" = new Property( name=targetPropertyName, control="auto", type=targetObject.properties.id.type, dbtype=targetObject.properties.id.dbtype, maxLength=targetObject.properties.id.maxLength, generator="none", relationship="many-to-one", relatedTo=objBName, required=true, onDelete="cascade" )
				, "sort_order"           = new Property( name="sort_order"      , control="auto", type="numeric"                      , dbtype="int"                            , maxLength=0                                   , generator="none", relationship="none"                           , required=false )
			  }
		};

		return autoObject;
	}

// PRIVATE HELPERS
	private struct function _mergeObjects( required struct unMergedObjects ) output=false {
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

	private struct function _mergeExtendedObjectMeta( required struct meta ) output=false {
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

	private void function _mergeProperties( required struct meta, required array properties, required string pathToCfc ) output=false {
		var prop         = "";
		var propName     = "";
		var orderedProps = _getOrderedPropertiesInAHackyWayBecauseRailoGivesThemInRandomOrder( pathToCfc = arguments.pathToCfc );

		param name="arguments.meta.properties"    default=StructNew( "linked" );
		param name="arguments.meta.propertyNames" default=ArrayNew(1);

		for( propName in orderedProps ){
			for( prop in arguments.properties ) {
				if ( prop.name eq propName ) {
					if ( not StructKeyExists( arguments.meta.properties, prop.name ) ) {
						arguments.meta.properties[ prop.name ] = {};
					}

					arguments.meta.properties[ prop.name ] = _readProperty( prop, arguments.meta.properties[ prop.name ] );

					if ( not arguments.meta.propertyNames.find( prop.name ) ) {
						ArrayAppend( arguments.meta.propertyNames, prop.name );
					}
				}
			}
		}
	}

	private void function _mergeMethods( required struct meta, required array methods ) output=false {
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

	private struct function _readProperty( required struct property, required struct inheritedProperty ) output=false {
		var prop = Duplicate( arguments.property );

		StructAppend( prop, inheritedProperty, false );

		StructDelete( prop, "name" );

		return prop;
	}

	private void function _addDefaultsToProperties( required struct properties ) output=false {
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

		for( var propName in properties ){
			var prop           = properties[ propName ];
			var isCoreProperty = ListFindNoCase( "id,label,datecreated,datemodified", propName );

			if ( ( prop.type ?: "" ) == "any" ) {
				StructDelete( prop, "type" );
			}
			if ( not isCoreProperty ) {
				StructAppend( prop, defaultAttributes, false );
			}

			if ( StructKeyExists( prop, "relationship" ) and prop.relationship neq "none" and prop.relatedTo eq "none" ) {
				prop.relatedTo = propName;

				if ( prop.relationship == "many-to-many" ) {
					prop.dbtype = "none";
				}
			}
		}
	}

	private string function _calculateDbFieldList( required struct properties ) output=false {
		var list = [];
		for( var propName in arguments.properties ){
			if ( ( arguments.properties[ propName ].dbtype ?: "" ) != "none" ) {
				list.append( propName );
			}
		}

		return list.toList();
	}

	private void function _mergeSystemPropertyDefaults( required struct meta ) output=false {
		param name="arguments.meta.propertyNames" default=ArrayNew(1);

		var defaults = {
			  id            = { type="string", dbtype="varchar" , control="none"     , maxLength="35", relationship="none", relatedto="none", generator="UUID", required="true", pk="true" }
			, label         = { type="string", dbtype="varchar" , control="textinput", maxLength="250", relationship="none", relatedto="none", generator="none", required="true" }
			, datecreated   = { type="date"  , dbtype="datetime", control="none"     , maxLength="0" , relationship="none", relatedto="none", generator="none", required="true" }
			, datemodified  = { type="date"  , dbtype="datetime", control="none"     , maxLength="0" , relationship="none", relatedto="none", generator="none", required="true" }
		};

		if ( arguments.meta.propertyNames.find( "label" ) ) {
			StructAppend( arguments.meta.properties.label, defaults.label, false );
		} elseif ( !arguments.meta.noLabel ) {
			arguments.meta.properties[ "label" ] = defaults[ "label" ];
			ArrayPrepend( arguments.meta.propertyNames, "label" );
		}

		if ( arguments.meta.propertyNames.find( "id" ) ) {
			StructAppend( arguments.meta.properties.id, defaults.id, false );
		} else {
			arguments.meta.properties[ "id" ] = defaults[ "id" ];
			ArrayPrepend( arguments.meta.propertyNames, "id" );
		}

		if ( arguments.meta.propertyNames.find( "datecreated" ) ) {
			StructAppend( arguments.meta.properties.datecreated, defaults.datecreated, false );
		} else {
			arguments.meta.properties[ "datecreated" ] = defaults[ "datecreated" ];
			ArrayAppend( arguments.meta.propertyNames, "datecreated" );
		}

		if ( arguments.meta.propertyNames.find( "datemodified" ) ) {
			StructAppend( arguments.meta.properties.datemodified, defaults.datemodified, false );
		} else {
			arguments.meta.properties[ "datemodified" ] = defaults[ "datemodified" ];
			ArrayAppend( arguments.meta.propertyNames, "datemodified" );
		}
	}

	private struct function _discoverIndexes( required struct properties, required string objectName ) output=false {
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

	private struct function _convertPropertiesToBeans( required struct properties ) output=false {
		var newProperties = StructNew( "linked" );
		var propName      = "";
		var propAttribs   = "";

		for( propName in arguments.properties ){
			propAttribs = Duplicate( arguments.properties[ propName ] );
			propAttribs.name = propName;

			newProperties[ propName ] = new Property( argumentCollection = propAttribs );
		}

		return newProperties;
	}

	private void function _fixOrderOfProperties( required struct meta ) output=false {
		param name="arguments.meta.propertyNames" default=ArrayNew(1);
		param name="arguments.meta.properties"    default=StructNew();

		var propName     = "";
		var orderedProps = StructNew( 'linked' );

		for( propName in arguments.meta.propertyNames ){
			orderedProps[ propName ] = arguments.meta.properties[ propName ];
		}

		arguments.meta.properties = orderedProps;
	}

	private array function _getOrderedPropertiesInAHackyWayBecauseRailoGivesThemInRandomOrder( required string pathToCfc ) output=false {
		var cfcContent      = FileRead( arguments.pathToCfc );
		var propertyMatches = $reSearch( 'property\s+[^;/>]*name="([a-zA-Z_\$][a-zA-Z0-9_\$]*)"', cfcContent );

		if ( StructKeyExists( propertyMatches, "$1" ) ) {
			return propertyMatches.$1;
		}

		return [];
	}

	private struct function $reSearch( required string regex, required string text ) output=false {
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

	private void function _defineLabelField( required struct objectMeta ) output=false {
		// if ( arguments.objectMeta.isPageType ) {
		// 	arguments.objectMeta.labelfield = arguments.objectMeta.labelfield ?: "page.title";
		// }
		if ( IsBoolean ( arguments.objectMeta.nolabel ?: "" ) && arguments.objectMeta.nolabel ) {
			arguments.objectMeta.labelfield = arguments.objectMeta.labelfield ?: "";
		} else {
			arguments.objectMeta.labelfield = arguments.objectMeta.labelfield ?: "label";
		}
		arguments.objectMeta.noLabel = arguments.objectMeta.noLabel ?: arguments.objectMeta.labelfield !== "label";
	}

	private any function _announceInterception() output=false {
		return _getInterceptorService().processState( argumentCollection=arguments );
	}

// GETTERS AND SETTERS
	private string function _getDsn() output=false {
		return _dsn;
	}
	private void function _setDsn( required string dsn ) output=false {
		_dsn = arguments.dsn;
	}

	private string function _getTablePrefix() output=false {
		return _tablePrefix;
	}
	private void function _setTablePrefix( required string tablePrefix ) output=false {
		_tablePrefix = arguments.tablePrefix;
	}

	private any function _getInterceptorService() output=false {
		return _interceptorService;
	}
	private void function _setInterceptorService( required any IiterceptorService ) output=false {
		_interceptorService = arguments.IiterceptorService;
	}
}