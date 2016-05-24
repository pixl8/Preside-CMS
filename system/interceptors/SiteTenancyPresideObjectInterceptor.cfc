component extends="coldbox.system.Interceptor" {

	property name="presideObjectService" inject="delayedInjector:presideObjectService";

// PUBLIC
	public void function configure() {}

	public void function postReadPresideObject( event, interceptData ) {
		var objectMeta = interceptData.objectMeta ?: {};

		objectMeta.siteTemplates = objectMeta.siteTemplates ?: _getSiteTemplateForObject( objectMeta.name );
		objectMeta.siteFiltered  = objectMeta.siteFiltered ?: false;

		if ( objectMeta.siteFiltered ) {
			_injectSiteTenancyFields( objectMeta );
		}
	}

	public void function prePrepareObjectFilter( event, interceptData ) {
		if ( _objectIsUsingSiteTenancy( interceptData.objectName ?: "" ) ) {
			interceptData.extraFilters = interceptData.extraFilters ?: [];
			interceptData.extraFilters.append( { filter = { "#interceptData.objectName#.site" = event.getSiteId() } } );
		}
	}

	public void function onCreateSelectDataCacheKey( event, interceptData ) {
		if ( _objectIsUsingSiteTenancy( interceptData.objectName ?: "" ) ) {
			interceptData.cacheKey = interceptData.cacheKey ?: "";
			interceptData.cacheKey &= "_" & event.getSiteId();
		}
	}

	public void function preInsertObjectData( event, interceptData ) {
		if ( _objectIsUsingSiteTenancy( interceptData.objectName ?: "" ) ) {
			interceptData.data      = interceptData.data      ?: {};
			interceptData.data.site = interceptData.data.site ?: event.getSiteId();
		}
	}

// PRIVATE HELPERS
	private string function _getSiteTemplateForObject( required string objectPath ) {
		var regex = "^.*?\.site-templates\.([^\.]+)\.preside-objects\..+$";

		if ( !ReFindNoCase( regex, arguments.objectPath ) ) {
			return "*";
		}

		return ReReplaceNoCase( arguments.objectPath, regex, "\1" );
	}

	private boolean function _objectIsUsingSiteTenancy( required string objectName ) {
		if ( !presideObjectService.objectExists( arguments.objectName ) ) {
			return false;
		}

		var usingSiteTenancy = presideObjectService.getObjectAttribute( arguments.objectName, "siteFiltered", false );

		return IsBoolean( usingSiteTenancy ) && usingSiteTenancy;
	}

	private void function _injectSiteTenancyFields( required struct meta ) {
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
	}
}