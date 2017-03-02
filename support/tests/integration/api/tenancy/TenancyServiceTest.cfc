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
		};
	}
}
