component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @dsn.inject         coldbox:setting:dsn
	 * @tablePrefix.inject coldbox:setting:presideObjectsTablePrefix
	 */
	public any function init( required string dsn, required string tablePrefix ) output=false {
		_setDsn( arguments.dsn );
		_setTablePrefix( arguments.tablePrefix );

		return this;
	}


// PUBLIC API METHODS
	public struct function readObject( required any object ) output=false {
		var meta          = _mergeExtendedObjectMeta( getMetaData( arguments.object ) );
		var componentName = ListLast( meta.name, "." );
		var key           = "";

		meta.tablePrefix   = meta.tablePrefix   ?: _getTablePrefix();
		meta.tableName     = meta.tableName     ?: componentName;
		meta.versioned     = meta.versioned     ?: true;
		meta.dsn           = meta.dsn           ?: _getDsn();
		meta.properties    = meta.properties    ?: StructNew();
		meta.dbFieldList   = meta.dbFieldList   ?: "";
		meta.propertyNames = meta.propertyNames ?: ArrayNew(1);
		meta.siteTemplates = meta.siteTemplates ?: _getSiteTemplateForObject( meta.name );
		meta.siteFiltered  = meta.siteFiltered  ?: false;
		meta.isPageType    = _isPageTypeObject( meta );


		if ( meta.siteFiltered ) {
			_injectSiteTenancyFields( meta );
		}

		_defineLabelField( meta );
		_mergeSystemPropertyDefaults( meta );
		_fixOrderOfProperties( meta );
		meta.properties = _convertPropertiesToBeans( meta.properties );

		meta.tableName = meta.tablePrefix & meta.tableName;


		meta.indexes = _discoverIndexes( meta.properties, componentName );

		return meta;
	}

	public struct function getAutoPivotObjectDefinition( required struct objectA, required struct objectB ) output=false {
		var tmp = "";
		var autoObject = "";
		var objAName = LCase( ListLast( objectA.name, "." ) );
		var objBName = LCase( ListLast( objectB.name, "." ) );

		if ( LCase( objAName ) gt LCase( objBName ) ) {
			tmp = Duplicate( objectA );
			objectA = Duplicate( objectB );
			objectB = Duplicate( tmp );

			tmp = objAName;
			objAName = objBName;
			objBName = tmp;
		}

		autoObject = {
			  dbFieldList = "#objAName#,#objBName#,sort_order"
			, dsn         = objectA.dsn
			, indexes     = { "ux_#objAName#__join__#objBName#" = { unique=true, fields="#objAName#,#objBName#" } }
			, name        = "#objAName#__join__#objBName#"
			, tableName   = objectA.tablePrefix & "#objAName#__join__#objBName#"
			, tablePrefix = objectA.tablePrefix
			, versioned   = ( ( objectA.versioned ?: false ) || ( objectB.versioned ?: false ) )
			, properties  = {
				  "#objAName#" = new Property( name=objAName    , control="auto", type=objectA.properties.id.type, dbtype=objectA.properties.id.dbtype, maxLength=objectA.properties.id.maxLength, generator="none", relationship="many-to-one", relatedTo=objAName, required=true, onDelete="cascade" )
				, "#objBName#" = new Property( name=objBName    , control="auto", type=objectB.properties.id.type, dbtype=objectB.properties.id.dbtype, maxLength=objectB.properties.id.maxLength, generator="none", relationship="many-to-one", relatedTo=objBName, required=true, onDelete="cascade" )
				, "sort_order" = new Property( name="sort_order", control="auto", type="numeric"                 , dbtype="int"                       , maxLength=0                              , generator="none", relationship="none"       , required=false )
			  }
		};

		return autoObject;
	}

// PRIVATE HELPERS
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
		param name="arguments.meta.dbFieldList"   default="";

		for( propName in orderedProps ){
			for( prop in arguments.properties ) {
				if ( prop.name eq propName ) {
					if ( not StructKeyExists( arguments.meta.properties, prop.name ) ) {
						arguments.meta.properties[ prop.name ] = {};
					}

					arguments.meta.properties[ prop.name ] = _readProperty( prop, arguments.meta.properties[ prop.name ] );

					if ( not ListFindNoCase( arguments.meta.dbFieldList, prop.name ) and ( arguments.meta.properties[ prop.name ].dbType ?: "" ) neq "none" ) {
						arguments.meta.dbFieldList = ListAppend( arguments.meta.dbFieldList, prop.name );
					}

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
		var prop              = Duplicate( arguments.property );
		var isCoreProperty    = ListFindNoCase( "id,label,datecreated,datemodified", prop.name );
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


		if ( prop.type eq "any" ) {
			StructDelete( prop, "type" );
		}

		if ( not isCoreProperty ) {
			StructAppend( prop, inheritedProperty, false );
			StructAppend( prop, defaultAttributes, false );
		}

		if ( StructKeyExists( prop, "relationship" ) and prop.relationship neq "none" and prop.relatedTo eq "none" ) {
			prop.relatedTo = prop.name;

			if ( prop.relationship == "many-to-many" ) {
				prop.dbtype = "none";
			}
		}

		StructDelete( prop, "name" );

		return prop;
	}

	private void function _mergeSystemPropertyDefaults( required struct meta ) output=false {
		param name="arguments.meta.propertyNames" default=ArrayNew(1);

		var defaults = {
			  id            = { type="string", dbtype="varchar"  , control="none"     , maxLength="35", relationship="none", relatedto="none", generator="UUID", required="true", pk="true" }
			, label         = { type="string", dbtype="varchar"  , control="textinput", maxLength="250", relationship="none", relatedto="none", generator="none", required="true" }
			, datecreated   = { type="date"  , dbtype="timestamp", control="none"     , maxLength="0" , relationship="none", relatedto="none", generator="none", required="true" }
			, datemodified  = { type="date"  , dbtype="timestamp", control="none"     , maxLength="0" , relationship="none", relatedto="none", generator="none", required="true" }
		};

		if ( arguments.meta.propertyNames.find( "label" ) ) {
			StructAppend( arguments.meta.properties.label, defaults.label, false );
		} elseif ( !arguments.meta.noLabel ) {
			arguments.meta.properties[ "label" ] = defaults[ "label" ];
			ArrayPrepend( arguments.meta.propertyNames, "label" );
			arguments.meta.dbFieldList = ListPrepend( arguments.meta.dbFieldList, "label" );
		}

		if ( arguments.meta.propertyNames.find( "id" ) ) {
			StructAppend( arguments.meta.properties.id, defaults.id, false );
		} else {
			arguments.meta.properties[ "id" ] = defaults[ "id" ];
			ArrayPrepend( arguments.meta.propertyNames, "id" );
			arguments.meta.dbFieldList = ListPrepend( arguments.meta.dbFieldList, "id" );
		}

		if ( arguments.meta.propertyNames.find( "datecreated" ) ) {
			StructAppend( arguments.meta.properties.datecreated, defaults.datecreated, false );
		} else {
			arguments.meta.properties[ "datecreated" ] = defaults[ "datecreated" ];
			ArrayAppend( arguments.meta.propertyNames, "datecreated" );
			arguments.meta.dbFieldList = ListAppend( arguments.meta.dbFieldList, "datecreated" );
		}

		if ( arguments.meta.propertyNames.find( "datemodified" ) ) {
			StructAppend( arguments.meta.properties.datemodified, defaults.datemodified, false );
		} else {
			arguments.meta.properties[ "datemodified" ] = defaults[ "datemodified" ];
			ArrayAppend( arguments.meta.propertyNames, "datemodified" );
			arguments.meta.dbFieldList = ListAppend( arguments.meta.dbFieldList, "datemodified" );
		}

		if ( arguments.meta.isPageType ) {
			_injectPageTypeFields( arguments.meta );
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

	private boolean function _isPageTypeObject( required struct objectMeta ) output=false {
		var objectPath = arguments.objectMeta.name ?: "";

		return ReFindNoCase( "\.page-types\.", objectPath );
	}

	private void function _defineLabelField( required struct objectMeta ) output=false {
		if ( arguments.objectMeta.isPageType ) {
			arguments.objectMeta.labelfield = arguments.objectMeta.labelfield ?: "page.title";
		}
		if ( IsBoolean ( arguments.objectMeta.nolabel ?: "" ) && arguments.objectMeta.nolabel ) {
			arguments.objectMeta.labelfield = arguments.objectMeta.labelfield ?: "";
		} else {
			arguments.objectMeta.labelfield = arguments.objectMeta.labelfield ?: "label";
		}
		arguments.objectMeta.noLabel = arguments.objectMeta.noLabel ?: arguments.objectMeta.labelfield !== "label";
	}

	private void function _injectPageTypeFields( required struct meta ) output=false {
		var defaultConfiguration = { relationship="many-to-one", relatedto="page", required=true, uniqueindexes="page", ondelete="cascade", onupdate="cascade", generator="none" };

		param name="arguments.meta.properties.page" default={};
		StructAppend( arguments.meta.properties.page, defaultConfiguration, false );

		if ( not arguments.meta.propertyNames.find( "page" ) ) {
			ArrayAppend( arguments.meta.propertyNames, "page" );
		}

		if ( not ListFindNoCase( arguments.meta.dbFieldList, "page" ) ) {
			arguments.meta.dbFieldList = ListAppend( arguments.meta.dbFieldList, "page" );
		}
	}

	private void function _injectSiteTenancyFields( required struct meta ) output=false {
		var defaultConfiguration = { relationship="many-to-one", relatedto="site", required=false, ondelete="cascade", onupdate="cascade", generator="none", indexes="_site", uniqueindexes="", control="none" };
		var indexNames           = [];

		for( var prop in arguments.meta.properties ){
			if ( prop == "site" ) { continue; }

			prop = arguments.meta.properties[ prop ];

			if ( Len( Trim( prop.indexes ?: "" ) ) ) {
				var newIndexDefinition = "";

				for( var ix in ListToArray( prop.indexes ) ) {
					var siteIndexName = ListFirst( ix, "|" ) & "|1";
					if ( !ListFindNoCase( defaultConfiguration.indexes, siteIndexName ) ) {
						defaultConfiguration.indexes = ListAppend( defaultConfiguration.indexes, siteIndexName );
					}

					if ( ListLen( ix, "|" ) > 1 ) {
						newIndexDefinition = ListAppend( newIndexDefinition, ListFirst( ix, "|" ) & "|" & Val( ListRest( ix, "|" ) )+1 );
					} else {
						newIndexDefinition = ListAppend( newIndexDefinition, ix & "|2" );
					}
				}

				prop.indexes = newIndexDefinition;
			}

			if ( Len( Trim( prop.uniqueindexes ?: "" ) ) ) {
				var newIndexDefinition = "";

				for( var ix in ListToArray( prop.uniqueindexes ) ) {
					var siteIndexName = ListFirst( ix, "|" ) & "|1";
					if ( !ListFindNoCase( defaultConfiguration.uniqueIndexes, siteIndexName ) ) {
						defaultConfiguration.uniqueIndexes = ListAppend( defaultConfiguration.uniqueIndexes, siteIndexName );
					}

					if ( ListLen( ix, "|" ) > 1 ) {
						newIndexDefinition = ListAppend( newIndexDefinition, ListFirst( ix, "|" ) & "|" & Val( ListRest( ix, "|" ) )+1 );
					} else {
						newIndexDefinition = ListAppend( newIndexDefinition, ix & "|2" );
					}
				}

				prop.uniqueindexes = newIndexDefinition;
			}
		}

		arguments.meta.properties.site = arguments.meta.properties.site ?: {};

		StructAppend( arguments.meta.properties.site, defaultConfiguration, false );

		if ( not arguments.meta.propertyNames.find( "site" ) ) {
			ArrayAppend( arguments.meta.propertyNames, "site" );
		}

		if ( not ListFindNoCase( arguments.meta.dbFieldList, "site" ) ) {
			arguments.meta.dbFieldList = ListAppend( arguments.meta.dbFieldList, "site" );
		}
	}

	private string function _getSiteTemplateForObject( required string objectPath ) output=false {
		var regex = "^.*?\.site-templates\.([^\.]+)\.preside-objects\..+$";

		if ( !ReFindNoCase( regex, arguments.objectPath ) ) {
			return "*";
		}

		return ReReplaceNoCase( arguments.objectPath, regex, "\1" );
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
}