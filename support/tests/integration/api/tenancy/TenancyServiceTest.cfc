component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "injectObjectTenancyProperties()", function(){
			it( "should do nothing to the passed object metadata when it is not using tenancy", function(){
				var service   = _getService();
				var meta      = { tenant="", blah=CreateUUId() };
				var untouched = Duplicate( meta );

				service.injectObjectTenancyProperties( meta );

				expect( meta ).toBe( untouched );
			} );

			it( "should add metadata about the tenancy configuration of the object when object configured for tenancy", function(){
				var config    = _getDefaultTestConfig();
				var service   = _getService( config );
				var meta      = { tenant="test" };
				var decorated = Duplicate( meta );

				decorated.tenancyConfig = { fk=config.test.defaultFk };

				service.injectObjectTenancyProperties( meta );

				expect( meta.tenancyConfig ?: "" ).toBe( decorated.tenancyConfig );
			} );

			it( "should inject the tenancy foreign keys when not already defined on the object", function(){
				var config    = _getDefaultTestConfig();
				var service   = _getService( config );
				var meta      = { tenant="site", properties={} };
				var decorated = Duplicate( meta );

				decorated.properties.site = { name="site", relationship="many-to-one", relatedTo="site", required=false, indexes="_site", ondelete="cascade", onupdate="cascade" };

				service.injectObjectTenancyProperties( meta );

				expect( meta.properties ).toBe( decorated.properties );
			} );

			it( "should decorate the pre-existing tenancy foreign keys", function(){
				var config    = _getDefaultTestConfig();
				var service   = _getService( config );
				var meta      = { tenant="site", properties={
					site = { required=true, test=CreateUUId() }
				} };
				var decorated = Duplicate( meta );

				decorated.properties.site = { name="site", relationship="many-to-one", relatedTo="site", required=true, indexes="_site", test=meta.properties.site.test, ondelete="cascade", onupdate="cascade" };

				service.injectObjectTenancyProperties( meta );

				expect( meta.properties ).toBe( decorated.properties );
			} );

			it( "should add the injected property to the array of property names stored against the objects meta", function(){
				var config    = _getDefaultTestConfig();
				var service   = _getService( config );
				var meta      = { tenant="test", propertyNames=[] };
				var decorated = Duplicate( meta );

				decorated.propertyNames = [ config.test.defaultFk ];

				service.injectObjectTenancyProperties( meta );

				expect( meta.propertyNames ).toBe( decorated.propertyNames );
			} );

			it( "should not add the injected properties to the array of property names stored against the objects meta when those object names are already present", function(){
				var config    = _getDefaultTestConfig();
				var service   = _getService( config );
				var meta      = { tenant="test", propertyNames=[ config.test.defaultFk ] };
				var decorated = Duplicate( meta );

				service.injectObjectTenancyProperties( meta );

				expect( meta.propertyNames ).toBe( decorated.propertyNames );
			} );

			it( "should add tenancy FKs into all indexes and unique indexes of the other properties", function(){
				fail( "but we haven't implemented this yet" );
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
/*
		describe( "objectIsUsingTenancy()", function(){
			it( "should do a bunch of stuff", function(){
				fail( "but not yet implemented" );
			} );
		} );

		describe( "decorateSelectDataCacheKey()", function(){
			it( "should do a bunch of stuff", function(){
				fail( "but not yet implemented" );
			} );
		} );

		describe( "addTenancyFieldsToInsertData()", function() {
			it( "should do a bunch of stuff", function(){
				fail( "but not yet implemented" );
			} );
		} );

		describe( "getTenancyFilter()", function(){
			it( "should do a bunch of stuff", function(){
				fail( "but not yet implemented" );
			} );
		} );

		describe( "setTenantId()", function(){
			it( "should do a bunch of stuff", function(){
				fail( "but not yet implemented" );
			} );
		} );

		describe( "getTenantId()", function(){
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

		service = createMock( object=service );

		return service;
	}

	private struct function _getDefaultTestConfig() {
		return {
			  site = { object="site", defaultfk="site" }
			, test = { object=CreateUUId(), defaultFk=CreateUUId() }
		};
	}
}
