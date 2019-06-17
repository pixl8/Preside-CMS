/**
 * The tenancy service provides the mostly invisible logic
 * for auto filtering data based on custom defined tenants.
 *
 * @presideService true
 * @singleton      true
 */
component displayName="Tenancy service" {

// CONSTRUCTOR
	/**
	 * @tenancyConfig.inject coldbox:setting:tenancy
	 *
	 */
	public any function init( required struct tenancyConfig ) {
		_setTenancyConfig( arguments.tenancyConfig );
		return this;
	}

// PUBLIC API
	public void function injectObjectTenancyProperties( required struct objectMeta, required string objectName ) {
		var siteFiltered = IsBoolean( objectMeta.siteFiltered ?: "" ) && objectMeta.siteFiltered;
		if ( siteFiltered ) {
			objectMeta.tenant = "site";
		}

		var tenant = ( objectMeta.tenant ?: "" ).trim();

		if ( tenant.len() ) {
			var config = _getTenancyConfig();
			if ( siteFiltered ) {
			}

			if ( !StructKeyExists( config, tenant ) ) {
				throw(
					  type    = "preside.tenancy.invalid.tenant"
					, message = "The [#arguments.objectName#] object specified the tenant, [#tenant#], but this tenant is not amongst the configured tenants for the system."
				);
			}

			var fk            = findObjectTenancyForeignKey( tenant, objectMeta );
			var tenancyObject = config[ tenant ].object;
			var fkProperty    = { name=fk, relationship="many-to-one", relatedTo=tenancyObject, required=false, indexes="_#fk#", ondelete="cascade", onupdate="cascade", control="none", adminViewGroup="system" };
			var indexNames    = [];

			objectMeta.propertyNames    = objectMeta.propertyNames ?: [];
			objectMeta.tenancyConfig    = { fk=fk };
			objectMeta.properties       = objectMeta.properties ?: {};
			objectMeta.properties[ fk ] = objectMeta.properties[ fk ] ?: {};

			if ( !objectMeta.propertyNames.findNoCase( fk ) ) {
				objectMeta.propertyNames.append( fk );
			}

			for( var prop in objectMeta.properties ){
				if ( prop == fk ) { continue; }

				prop = objectMeta.properties[ prop ];

				if ( Len( Trim( prop.indexes ?: "" ) ) ) {
					var newIndexDefinition = "";

					for( var ix in ListToArray( prop.indexes ) ) {
						var indexName = ListFirst( ix, "|" ) & "|1";
						if ( !ListFindNoCase( fkProperty.indexes, indexName ) ) {
							fkProperty.indexes = ListAppend( fkProperty.indexes, indexName );
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
						var indexName = ListFirst( ix, "|" ) & "|1";
						if ( !ListFindNoCase( ( fkProperty.uniqueIndexes ?: "" ), indexName ) ) {
							fkProperty.uniqueIndexes = ListAppend( ( fkProperty.uniqueIndexes ?: "" ), indexName );
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

			StructAppend( objectMeta.properties[ fk ], fkProperty, false );
		}
	}

	public string function findObjectTenancyForeignKey( required string tenant, required struct objectMeta ) {
		var props = objectMeta.properties ?: {};
		for( var propName in props ) {
			var prop = props[ propName ];
			var fkForTenant = ListToArray( prop.fkForTenant ?: "" );

			if ( fkForTenant.findNoCase( arguments.tenant ) ) {
				return propName;
			}
		}

		return getDefaultFkForTenant( arguments.tenant );
	}

	public string function getDefaultFkForTenant( required string tenant ) {
		var config = _getTenancyConfig();

		return config[ tenant ].defaultFk ?: "";
	}

	public string function getObjectTenant( required string objectName ) {
		return $getPresideObjectService().getObjectAttribute( objectName, "tenant" );
	}

	public string function getTenantFkForObject( required string objectName ) {
		var tenancyConfig = $getPresideObjectService().getObjectAttribute( objectName, "tenancyConfig" );

		return tenancyConfig.fk ?: "";
	}

	public boolean function objectIsUsingTenancy( required string objectName, required string tenant ) {
		var objectTenant = getObjectTenant( arguments.objectName );

		return objectTenant == arguments.tenant;
	}

	public void function setTenantId( required string tenant, required string id ) {
		request.__presideTenancy = request.__presideTenancy ?: {};
		request.__presideTenancy[ arguments.tenant ] = arguments.id;
	}

	public string function getTenantId( required string tenant ) {
		return request.__presideTenancy[ arguments.tenant ] ?: "";
	}

	public string function getTenancyCacheKey( required string objectName, array bypassTenants=[], struct tenantIds={} ) {
		var tenant = getObjectTenant( arguments.objectName );

		if ( tenant.len() && !arguments.bypassTenants.findNoCase( tenant ) ) {
			return "-" & ( arguments.tenantIds[ tenant ] ?: getTenantId( tenant ) );
		}

		return "";
	}

	public struct function getTenancyFieldsForInsertData( required string objectName, array bypassTenants=[] ) {
		var tenant = getObjectTenant( arguments.objectName );
		var fields = {};

		if ( tenant.len() && !arguments.bypassTenants.findNoCase( tenant ) ) {
			var fk       = getTenantFkForObject( arguments.objectName );
			var tenantId = getTenantId( tenant );

			fields[ fk ] = tenantId;
		}

		return fields;
	}

	public struct function getTenancyFilter( required string objectName, array bypassTenants=[], struct tenantIds={} ) {
		var tenant = getObjectTenant( arguments.objectName );

		if ( tenant.len() && !arguments.bypassTenants.findNoCase( tenant ) ) {
			var fk            = getTenantFkForObject( arguments.objectName );
			var tenantId      = arguments.tenantIds[ tenant ] ?: getTenantId( tenant );
			var config        = _getTenancyConfig();
			var filterHandler = config[ tenant ].getFilterHandler ?: "tenancy.#tenant#.getFilter";
			var coldbox       = $getColdbox();
			var defaultFilter = { filter={ "#arguments.objectName#.#fk#"=tenantId } };

			if ( coldbox.handlerExists( filterHandler ) ) {
				var filter = coldbox.runEvent(
					  event          = filterHandler
					, private        = true
					, prePostExempt  = true
					, eventArguments = {
						  objectName    = arguments.objectName
						, fk            = fk
						, defaultFilter = defaultFilter
						, tenantId      = tenantId
					  }
				);

				if ( IsNull( local.filter ) ) {
					return defaultFilter;
				}

				return filter;
			}

			return defaultFilter;
		}

		return {};
	}

	public void function setRequestTenantIds() {
		var config  = _getTenancyConfig();
		var coldbox = $getColdbox();

		for( var tenant in config ) {
			var handler = config[ tenant ].getIdHandler ?: "tenancy.#tenant#.getId";

			if ( coldbox.handlerExists( handler ) ) {
				var id = coldbox.runEvent(
					  event         = handler
					, private       = true
					, prePostExempt = true
				);

				if ( !IsNull( local.id ) ) {
					setTenantId( tenant, id );
				}
			}
		}
	}

// GETTERS AND SETTERS
	private struct function _getTenancyConfig() {
		return _tenancyConfig;
	}
	private void function _setTenancyConfig( required struct tenancyConfig ) {
		_tenancyConfig = arguments.tenancyConfig;
	}

}