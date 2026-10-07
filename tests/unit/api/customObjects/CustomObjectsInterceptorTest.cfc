component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "record scoping", function(){
			it( "should filter selects, updates and deletes to the custom object", function(){
				var interceptor = _interceptor( true );
				var selectArgs  = { objectName="cobj_widget", extraFilters=[] };
				var updateArgs  = { objectName="cobj_widget", extraFilters=[], data={} };
				var deleteArgs  = { objectName="cobj_widget", extraFilters=[] };

				interceptor.preSelectObjectData( {}, selectArgs );
				interceptor.preUpdateObjectData( {}, updateArgs );
				interceptor.preDeleteObjectData( {}, deleteArgs );

				expect( selectArgs.extraFilters[ 1 ].filter[ "cobj_widget.custom_object" ] ).toBe( "definition-1" );
				expect( updateArgs.extraFilters[ 1 ].filter[ "cobj_widget.custom_object" ] ).toBe( "definition-1" );
				expect( deleteArgs.extraFilters[ 1 ].filter[ "cobj_widget.custom_object" ] ).toBe( "definition-1" );
				expect( updateArgs.data.custom_object ).toBe( "definition-1" );
			} );

			it( "should set custom_object on insert", function(){
				var interceptor = _interceptor( true );
				var insertArgs  = { objectName="cobj_widget", data={ label="One" } };

				interceptor.preInsertObjectData( {}, insertArgs );

				expect( insertArgs.data.custom_object ).toBe( "definition-1" );
				expect( StructKeyExists( insertArgs, "interceptorResult" ) ).toBeFalse();
			} );

			it( "should include the custom object id in the select cache key", function(){
				var interceptor = _interceptor( true );
				var args        = { objectName="cobj_widget", cacheKey="abc" };

				interceptor.onCreateSelectDataCacheKey( {}, args );

				expect( args.cacheKey ).toBe( "abccustomObjectdefinition-1" );
			} );
		} );

		describe( "record permissions", function(){
			it( "should keep scoping a select without denying it", function(){
				var interceptor = _interceptor( false );
				var selectArgs  = { objectName="cobj_widget", extraFilters=[] };

				interceptor.preSelectObjectData( {}, selectArgs );

				expect( StructKeyExists( selectArgs, "interceptorResult" ) ).toBeFalse();
				expect( selectArgs.extraFilters[ 1 ].filter[ "cobj_widget.custom_object" ] ).toBe( "definition-1" );
			} );
		} );
	}

	private any function _interceptor( required boolean allowed ) {
		var service        = createMock( object=new preside.system.services.customObjects.CustomObjectsService() );
		var poService      = createStub();
		var login          = createStub();
		var permissions    = createStub();
		var controller     = createStub();
		var logBox         = createStub();
		var requestService = createStub();

		poService.$( "objectExists", true );
		poService.$( method="getObjectAttribute", callback=function(){
			return "definition-1";
		} );
		poService.$( method="selectData", callback=function(){
			return [];
		} );
		login.$( "getLoggedInUserId", "user-1" );
		login.$( "isSystemUser", arguments.allowed );
		permissions.$( "listUserGroups", [] );

		service.$property( propertyName="presideObjectService", mock=poService );
		service.$property( propertyName="loginService", mock=login );
		service.$property( propertyName="permissionService", mock=permissions );

		controller.$( "getLogBox", logBox );
		logBox.$( "getLogger", createStub() );
		controller.$( "getRequestService", requestService );
		requestService.$( "getFlashScope", createStub() );
		controller.$( "getCacheBox", createStub() );
		controller.$( "getWireBox", createStub() );
		controller.$( "getSetting", [] );
		controller.$( "getInterceptorService", createStub() );

		var interceptor = createMock( object=new preside.system.interceptors.CustomObjectsInterceptor( controller=controller ) );

		interceptor.$property( propertyName="customObjectsService", mock=service );

		return interceptor;
	}

}
