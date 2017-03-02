component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "injectObjectTenancyProperties()", function(){
			it( "should do nothing to the passed object metadata when it is not using tenancy", function(){
				var service    = _getService();
				var meta       = { tenant="", blah=CreateUUId() };
				var objectName = "test";
				var untouched  = Duplicate( meta );

				service.injectObjectTenancyProperties( meta, objectName );

				expect( meta ).toBe( untouched );
			} );

			it( "should add metadata about the tenancy configuration of the object when object configured for tenancy", function(){
				var config     = _getDefaultTestConfig();
				var service    = _getService( config );
				var meta       = { tenant="test" };
				var objectName = "test";
				var decorated  = Duplicate( meta );

				decorated.tenancyConfig = { fk=config.test.defaultFk };

				service.injectObjectTenancyProperties( meta, objectName );

				expect( meta.tenancyConfig ?: "" ).toBe( decorated.tenancyConfig );
			} );

			it( "should inject the tenancy foreign keys when not already defined on the object", function(){
				var config     = _getDefaultTestConfig();
				var service    = _getService( config );
				var meta       = { tenant="site", properties={} };
				var objectName = "test";
				var decorated  = Duplicate( meta );

				decorated.properties.site = { name="site", relationship="many-to-one", relatedTo="site", required=false, indexes="_site", ondelete="cascade", onupdate="cascade" };

				service.injectObjectTenancyProperties( meta, objectName );

				expect( meta.properties ).toBe( decorated.properties );
			} );

			it( "should decorate the pre-existing tenancy foreign keys", function(){
				var config     = _getDefaultTestConfig();
				var service    = _getService( config );
				var meta       = { tenant="site", properties={
					site = { required=true, test=CreateUUId() }
				} };
				var objectName = "test";
				var decorated  = Duplicate( meta );

				decorated.properties.site = { name="site", relationship="many-to-one", relatedTo="site", required=true, indexes="_site", test=meta.properties.site.test, ondelete="cascade", onupdate="cascade" };

				service.injectObjectTenancyProperties( meta, objectName );

				expect( meta.properties ).toBe( decorated.properties );
			} );

			it( "should add the injected property to the array of property names stored against the objects meta", function(){
				var config     = _getDefaultTestConfig();
				var service    = _getService( config );
				var meta       = { tenant="test", propertyNames=[] };
				var objectName = "test";
				var decorated  = Duplicate( meta );

				decorated.propertyNames = [ config.test.defaultFk ];

				service.injectObjectTenancyProperties( meta, objectName );

				expect( meta.propertyNames ).toBe( decorated.propertyNames );
			} );

			it( "should not add the injected properties to the array of property names stored against the objects meta when those object names are already present", function(){
				var config     = _getDefaultTestConfig();
				var service    = _getService( config );
				var meta       = { tenant="test", propertyNames=[ config.test.defaultFk ] };
				var decorated  = Duplicate( meta );
				var objectName = "test";

				service.injectObjectTenancyProperties( meta, objectName );

				expect( meta.propertyNames ).toBe( decorated.propertyNames );
			} );

			it( "should throw an informative error when the defined tenant is not configured", function(){
				var service     = _getService();
				var meta        = { tenant="blah" };
				var errorThrown = false;
				var objectName  = "test";

				try {
					service.injectObjectTenancyProperties( meta, objectName );
				} catch( "preside.tenancy.invalid.tenant" e ) {
					errorThrown = true;
					expect( e.message ).toBe( "The [test] object specified the tenant, [blah], but this tenant is not amongst the configured tenants for the system." );
				}

				expect( errorThrown ).toBeTrue( "No error was thrown" );

			} );

			it( "should add tenancy FKs into all indexes and unique indexes of the other properties", function(){
				var config     = _getDefaultTestConfig();
				var service    = _getService( config );
				var meta       = { tenant="site", properties={
					  prop1 = { indexes="ix1", uniqueindexes="ux1" }
					, prop2 = { indexes="ix2|1,ix3" }
					, prop3 = { indexes="ix2|2", uniqueindexes="ux2|2" }
					, prop4 = { uniqueindexes="ux2|1" }
				} };
				var objectName = "test";
				var decorated  = Duplicate( meta );

				decorated.properties.prop1.indexes       = "ix1|2";
				decorated.properties.prop1.uniqueindexes = "ux1|2";
				decorated.properties.prop2.indexes       = "ix2|2,ix3|2";
				decorated.properties.prop3.indexes       = "ix2|3";
				decorated.properties.prop3.uniqueindexes = "ux2|3";
				decorated.properties.prop4.uniqueindexes = "ux2|2";

				decorated.properties.site = {
					  name          = "site"
					, relationship  = "many-to-one"
					, relatedTo     = "site"
					, required      = false
					, indexes       = "_site,ix1|1,ix2|1,ix3|1"
					, uniqueindexes = "ux1|1,ux2|1"
					, ondelete      = "cascade"
					, onupdate      = "cascade"
				};

				service.injectObjectTenancyProperties( meta, objectName );

				expect( meta.properties ).toBe( decorated.properties );
			} );

			it( "should treat the 'siteFiltered=true' attribute on an object to be a synonym of tenant=site", function(){
				var config     = _getDefaultTestConfig();
				var service    = _getService( config );
				var meta       = { sitefiltered=true };
				var objectName = "test";
				var decorated  = Duplicate( meta );

				decorated.tenancyConfig = { fk="site" };

				service.injectObjectTenancyProperties( meta, objectName );

				expect( meta.tenancyConfig ?: "" ).toBe( decorated.tenancyConfig );
			} );
		} );

		describe( "findObjectTenancyForeignKey()", function(){
			it( "should return the property name of the first property that declares itself the tenancy FK for the given tenant", function(){
				var service   = _getService();
				var meta      = { tenant="site", properties={
					  id = { stuff="blah", etc=CreateUUId() }
					, diffThanDefault = { fkForTenant="site" }
				} };

				expect( service.findObjectTenancyForeignKey( "site", meta ) ).toBe( "diffThanDefault" );
			} );

			it( "should return the default property name from tenancy configuration when no properties declare themselves the fk", function(){
				var service   = _getService();
				var meta      = { tenant="site", properties={
					  id = { stuff="blah", etc=CreateUUId() }
					, anotherprop = { oi="you" }
				} };

				expect( service.findObjectTenancyForeignKey( "site", meta ) ).toBe( "site" );
			} );
		} );

		describe( "getDefaultFkForTenant()", function(){
			it( "should return the configured default FK for the given tenant", function(){
				var config  = _getDefaultTestConfig();
				var service = _getService( config );
				var tenant  = "test";

				expect( service.getDefaultFkForTenant( tenant ) ).toBe( config[ tenant ].defaultFk );
			} );

			it( "should return an empty string when the tenant is not defined", function(){
				var service = _getService();
				var tenant  = CreateUUId();

				expect( service.getDefaultFkForTenant( tenant ) ).toBe( "" );
			} );
		} );

		describe( "objectIsUsingTenancy()", function(){
			it( "should return true when the passed in object is using the supplied tenant", function(){
				var service    = _getService();
				var objectName = CreateUUId();
				var tenant     = CreateUUId();

				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectName, "tenant" ).$results( tenant );

				expect( service.objectIsUsingTenancy( objectname, tenant ) ).toBe( true );
			} );

			it( "should return false when the passed-in object does not have any tenant", function(){
				var service    = _getService();
				var objectName = CreateUUId();
				var tenant     = CreateUUId();

				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectName, "tenant" ).$results( "" );

				expect( service.objectIsUsingTenancy( objectname, tenant ) ).toBe( false );
			} );

			it( "should return false when the passed-in object has a different tenant", function(){
				var service    = _getService();
				var objectName = CreateUUId();
				var tenant     = CreateUUId();

				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectName, "tenant" ).$results( CreateUUId() );

				expect( service.objectIsUsingTenancy( objectname, tenant ) ).toBe( false );
			} );
		} );

		describe( "getObjectTenant()", function(){
			it( "should return the @tenant attribute defined on the object", function(){
				var service    = _getService();
				var objectName = CreateUUId();
				var tenant     = CreateUUId();

				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectName, "tenant" ).$results( tenant );

				expect( service.getObjectTenant( objectname ) ).toBe( tenant );
			} );
		} );

		describe( "get/setTenantId()", function(){
			it( "should set the ID of the given tenant for the request", function(){
				var service  = _getService();
				var tenant   = "site";
				var tenantId = CreateUUId();

				expect( service.getTenantId( tenant ) ).toBe( "" );
				service.setTenantId( tenant, tenantId );
				expect( service.getTenantId( tenant ) ).toBe( tenantId );
				expect( service.getTenantId( "test" ) ).toBe( "" );
				expect( service.getTenantId( tenant ) ).toBe( tenantId );

			} );
		} );

		describe( "decorateSelectDataCacheKey()", function(){
			it( "should do nothing when the object is not using any tenancy", function(){
				var service    = _getService();
				var objectName = CreateUUId();
				var tenant     = "";
				var cacheKey   = CreateUUId();

				service.$( "getObjectTenant" ).$args( objectName ).$results( tenant );

				expect( service.decorateSelectDataCacheKey( objectName, cacheKey ) ).toBe( cacheKey );
			} );

			it( "should add the current tenant value on to the end of the cache key when the object has a tenant", function(){
				var service    = _getService();
				var objectName = CreateUUId();
				var tenant     = "mytenant";
				var tenantId   = CreateUUId();
				var cacheKey   = CreateUUId();

				service.$( "getObjectTenant" ).$args( objectName ).$results( tenant );
				service.$( "getTenantId" ).$args( tenant ).$results( tenantId );

				expect( service.decorateSelectDataCacheKey( objectName, cacheKey ) ).toBe( cacheKey & "-" & tenantId );
			} );
		} );

		describe( "getTenantFkForObject()", function(){
			it( "should return the configured FK for the given object", function(){
				var service       = _getService();
				var objectName    = CreateUUId();
				var tenancyConfig = { fk=CreateUUId() };

				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectName, "tenancyConfig" ).$results( tenancyConfig );

				expect( service.getTenantFkForObject( objectname ) ).toBe( tenancyConfig.fk );
			} );
		} );

		describe( "addTenancyFieldsToInsertData()", function() {
			it( "should do nothing when the object is not using tenancy", function(){
				var service = _getService();
				var objectName = "test";
				var data       = { blah=CreateUUId(), title="Test title" };
				var untouched  = Duplicate( data );

				service.$( "getObjectTenant" ).$args( objectName ).$results( "" );

				service.addTenancyFieldsToInsertData( objectName, data );

				expect( data ).toBe( untouched );
			} );

			it( "should add the currently set tenant ID for the tenant that the object uses", function(){
				var service    = _getService();
				var objectName = "testthis";
				var tenant     = "test";
				var tenantId   = CreateUUId();
				var data       = { blah=CreateUUId(), title="Test title" };
				var modified   = Duplicate( data );
				var fk         = CreateUUId();

				modified[ fk ] = tenantId;

				service.$( "getObjectTenant" ).$args( objectName ).$results( tenant );
				service.$( "getTenantFkForObject" ).$args( objectName ).$results( fk );
				service.$( "getTenantId" ).$args( tenant ).$results( tenantId );

				service.addTenancyFieldsToInsertData( objectName, data );

				expect( data ).toBe( modified );
			} );
		} );

/*
		describe( "getTenancyFilter()", function(){
			it( "should do a bunch of stuff", function(){
				fail( "but not yet implemented" );
			} );
		} );
*/
	}

// PRIVATE HELPERS
	private any function _getService( struct tenancyConfig=_getDefaultTestConfig() ) {
		var service = new preside.system.services.tenancy.TenancyService(
			tenancyConfig = arguments.tenancyConfig
		);

		mockPresideObjectService = CreateEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );

		service = createMock( object=service );
		service.$( "$getPresideObjectService", mockPresideObjectService );

		return service;
	}

	private struct function _getDefaultTestConfig() {
		return {
			  site = { object="site", defaultfk="site" }
			, test = { object=CreateUUId(), defaultFk=CreateUUId() }
		};
	}
}
