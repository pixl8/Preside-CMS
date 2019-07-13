component extends="tests.resources.HelperObjects.PresideBddTestCase"{

	function run(){
		viewFolders = [
			  "/tests/resources/presideObjectService/_dataViews/views1"
			, "/tests/resources/presideObjectService/_dataViews/views2"
			, "/tests/resources/presideObjectService/_dataViews/views3"
		];

		describe( "renderView()", function(){

			it( "should fetch data from preside object service with field list derived from view", function(){
				var svc = _getPresideObjectViewService( [ viewFolders[1] ] );
				var log = "";
				var expectedArguments = {
					  objectName   = "object_b"
					, selectFields = [ "label as title", "object_b.datecreated as datecreated", "object_b.id as _id" ]
					, autoGroupBy  = true
				};

				mockPresideObjectService.$( "selectData", QueryNew('') );
				mockRendererPlugin.$( "renderView", "" );
				mockRendererPlugin.$( "locateView", "/tests/resources/presideObjectService/_dataViews/views3/preside-objects/object_b/index" );

				svc.renderView( presideObject = "object_b", view="preside-objects/object_b/index" );

				log = mockPresideObjectService.$callLog().selectData;

				expect( log.len() ).toBe( 1 );

				expect( log[1].objectName   ?: "" ).toBe( expectedArguments.objectName );
				expect( log[1].selectFields ?: "" ).toBe( expectedArguments.selectFields );
			} );

			it( "should forward all relevant arguments passed to the select data call so that we can pass in filters and sort order, etc.", function(){
				var svc = _getPresideObjectViewService( [ viewFolders[1], viewFolders[2] ] );
				var log = "";
				var passedArgs = {
					  presideObject = "object_b"
					, view          = "preside-objects/object_b/full"
					, sortBy        = "this"
					, filter        = "fubar = :this"
					, filterArgs    = { this = "is a test" }
					, anything      = "really"
				}
				var expectedArguments = {
					  objectName         = "object_b"
					, selectFields       = [ "label as title", "object_e.label as category", "object_b.datecreated as datecreated", "object_b.id as _id" ]
					, sortBy             = "this"
					, filter             = "fubar = :this"
					, filterArgs         = { this = "is a test" }
					, anything           = "really"
					, returnType         = "string"
					, args               = {}
					, allowDraftVersions = false
					, autoGroupBy        = true
				};
				var actualForwardedArgs = "";
				var expectedArgumemntNames = StructKeyArray( expectedArguments );
				var actualForwardedArgNames = "";

				mockPresideObjectService.$( "selectData", QueryNew('') );
				mockRendererPlugin.$( "renderView", "" );
				mockRendererPlugin.$( "locateView", "/tests/resources/presideObjectService/_dataViews/views1/preside-objects/object_b/full" );

				svc.renderView( argumentCollection = passedArgs );

				log = mockPresideObjectService.$callLog().selectData;

				expect( log.len() ).toBe( 1 );

				actualForwardedArgs = log[1];
				actualForwardedArgNames = StructKeyArray( actualForwardedArgs );

				ArraySort( expectedArgumemntNames, "textnocase" );
				ArraySort( actualForwardedArgNames, "textnocase" );

				expect( actualForwardedArgNames ).toBe( expectedArgumemntNames );
				for( var arg in expectedArgumemntNames ){
					expect( actualForwardedArgs[ arg ] ).toBe( expectedArguments[ arg ] );
				}
			} );

			it( "should render each record individually", function(){
				var svc            = _getPresideObjectViewService( [ viewFolders[1], viewFolders[2] ] );
				var expectedResult = "1-two-thr33";
				var actualResult   = "";
				var mockData       = QueryNew( "this,is,some,data");
				var log            = "";

				QueryAddRow( mockData, { "this":"rocks1","is":"a test1","some":"data1","data":"nice1" } );
				QueryAddRow( mockData, { "this":"rocks2","is":"a test2","some":"data2","data":"nice2" } );
				QueryAddRow( mockData, { "this":"rocks3","is":"a test3","some":"data3","data":"nice3" } );

				mockPresideObjectService.$( "selectData", mockData );
				mockRendererPlugin.$( "renderView" ).$results( "1", "-two", "-thr33" );
				mockRendererPlugin.$( "locateView", "/tests/resources/presideObjectService/_dataViews/views1/preside-objects/object_b/full" );

				actualResult = svc.renderView(
					  presideObject = "object_b"
					, view          = "preside-objects/object_b/full"
				);

				expect( actualResult ).toBe( expectedResult );

				log = mockRendererPlugin.$callLog().renderView;

				expect( log.len() ).toBe( mockData.recordCount );

				for( var i=1; i lte mockData.recordCount; i++ ){
					expect( log[i].view                ).toBe( "preside-objects/object_b/full" );
					expect( StructCount( log[i].args ) ).toBe( 4 );
					expect( log[i].args.this           ).toBe( mockData.this[i] );
					expect( log[i].args.is             ).toBe( mockData.is[i]   );
					expect( log[i].args.some           ).toBe( mockData.some[i] );
					expect( log[i].args.data           ).toBe( mockData.data[i] );
				}
			} );
		} );
	}

	private any function _getPresideObjectViewService( folders ) {
		mockPresideObjectService = createMock( "preside.system.services.presideObjects.presideObjectViewService" );
		mockRendererService      = createMock( "preside.system.services.rendering.ContentRendererService" );
		mockRendererPlugin       = createMock( "preside.system.coldboxModifications.services.Renderer" );
		mockColdbox              = createEmptyMock( "preside.system.coldboxModifications.Controller" );
		mockRequestContext       = createStub();

		var service = new preside.system.services.presideObjects.presideObjectViewService(
			  viewDirectories        = folders
			, presideObjectService   = mockPresideObjectService
			, presideContentRenderer = mockRendererService
			, coldboxRenderer        = mockRendererPlugin
			, cacheBox               = _getCachebox()
		);

		service = createMock( object=service );
		service.$( "$isAdminUserLoggedIn", false );
		service.$( "$getColdbox", mockColdbox );
		service.$( "$getRequestContext", mockRequestContext );
		service.$( "_getVersioningArgsForSelectData", {} );

		mockRequestContext.$( "showNonLiveContent", false );

		return service;
	}
}