component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "injectObjectTenancyProperties()", function(){
			it( "should do nothing to the passed object metadata when it is not using tenancy", function(){
				var service   = _getService();
				var meta      = { tenants="", blah=CreateUUId() };
				var untouched = Duplicate( meta );

				service.injectObjectTenancyProperties( meta );

				expect( meta ).toBe( untouched );
			} );

			it( "should add metadata about the tenancy configuration of the object when object configured for tenancy", function(){
				var config    = _getDefaultTestConfig();
				var service   = _getService( config );
				var meta      = { tenants="site,test" };
				var decorated = Duplicate( meta );

				decorated.tenancyConfig = {
					  site = { fk="site" }
					, test = { fk=config.test.defaultFk }
				};

				service.injectObjectTenancyProperties( meta );

				expect( meta.tenancyConfig ?: "" ).toBe( decorated.tenancyConfig );
			} );
		} );

		describe( "findObjectTenancyForeignKey()", function(){
			it( "should return the property name of the first property that declares itself the tenancy FK for the given tenant", function(){
				var service   = _getService();
				var meta      = { tenants="site", properties={
					  id = { stuff="blah", etc=CreateUUId() }
					, diffThanDefault = { fkForTenant="site" }
				} };

				expect( service.findObjectTenancyForeignKey( "site", meta ) ).toBe( "diffThanDefault" );
			} );

			it( "should return the default property name from tenancy configuration when no properties declare themselves the fk", function(){
				var service   = _getService();
				var meta      = { tenants="site", properties={
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
