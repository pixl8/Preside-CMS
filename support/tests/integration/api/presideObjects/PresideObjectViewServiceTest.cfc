component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// setup, teardown, etc.
	public void function setup(){
		super.setup();

		viewFolders = [
			  "/tests/resources/presideObjectService/_dataViews/views1"
			, "/tests/resources/presideObjectService/_dataViews/views2"
			, "/tests/resources/presideObjectService/_dataViews/views3"
		];
	}

// tests
	function test01_renderView_shouldFetchDataFromPresideObjectServiceWithFieldListDerivedFromView() output=false {
		var svc = _getPresideObjectViewService( [ viewFolders[1] ] );
		var log = "";
		var expectedArguments = {
			  objectName   = "object_b"
			, selectFields = [ "label as title", "object_b.datecreated as datecreated", "object_b.id as _id" ]
		};

		mockPresideObjectService.$( "selectData", QueryNew('') );
		mockRendererPlugin.$( "renderView", "" );
		mockRendererPlugin.$( "locateView", "/tests/resources/presideObjectService/_dataViews/views3/preside-objects/object_b/index" );

		svc.renderView( presideObject = "object_b", view="preside-objects/object_b/index" );

		log = mockPresideObjectService.$callLog().selectData;

		super.assertEquals( 1, log.len(), "Expected a single call to selectData(), instead [#log.len()#] were made" );

		super.assertEquals( expectedArguments.objectName  , log[1].objectName   ?: "" );
		super.assertEquals( expectedArguments.selectFields, log[1].selectFields ?: "" );
	}


	function test02_renderView_shouldForwardAllRelevantArgumentsPassedToTheSelectDataCall_soThatWeCanPassInFiltersAndSortOrdersEtc() output=false {
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
			  objectName   = "object_b"
			, selectFields = [ "label as title", "object_e.label as category", "object_b.datecreated as datecreated", "object_b.id as _id" ]
			, sortBy = "this"
			, filter = "fubar = :this"
			, filterArgs = { this = "is a test" }
			, anything = "really"
			, returnType = "string"
			, args       = {}
		};
		var actualForwardedArgs = "";
		var expectedArgumemntNames = StructKeyArray( expectedArguments );
		var actualForwardedArgNames = "";

		mockPresideObjectService.$( "selectData", QueryNew('') );
		mockRendererPlugin.$( "renderView", "" );
		mockRendererPlugin.$( "locateView", "/tests/resources/presideObjectService/_dataViews/views1/preside-objects/object_b/full" );

		svc.renderView( argumentCollection = passedArgs );

		log = mockPresideObjectService.$callLog().selectData;

		super.assertEquals( 1, log.len(), "Expected a single call to selectData(), instead [#log.len()#] were made" );

		actualForwardedArgs = log[1];
		actualForwardedArgNames = StructKeyArray( actualForwardedArgs );

		ArraySort( expectedArgumemntNames, "textnocase" );
		ArraySort( actualForwardedArgNames, "textnocase" );

		super.assertEquals( expectedArgumemntNames, actualForwardedArgNames );
		for( var arg in expectedArgumemntNames ){
			super.assertEquals( expectedArguments[arg], actualForwardedArgs[arg] );
		}
	}

	function test03_renderView_shouldRenderEachRecordIndividually() output=false {
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

		super.assertEquals( expectedResult, actualResult );

		log = mockRendererPlugin.$callLog().renderView;

		super.assertEquals( mockData.recordCount, log.len() );

		for( var i=1; i lte mockData.recordCount; i++ ){
			super.assertEquals( "preside-objects/object_b/full", log[i].view );
			super.assertEquals( 4, StructCount( log[i].args ) );
			super.assertEquals( mockData.this[i], log[i].args.this );
			super.assertEquals( mockData.is[i]  , log[i].args.is   );
			super.assertEquals( mockData.some[i], log[i].args.some );
			super.assertEquals( mockData.data[i], log[i].args.data );
		}
	}


// private utility
	private any function _getPresideObjectViewService( folders ) output=false {
		mockPresideObjectService = createMock( "preside.system.services.presideObjects.presideObjectViewService" );
		mockRendererService      = createMock( "preside.system.services.rendering.ContentRendererService" );
		mockRendererPlugin       = createMock( "preside.system.coldboxModifications.plugins.Renderer" );

		return new preside.system.services.presideObjects.presideObjectViewService(
			  viewDirectories        = folders
			, presideObjectService   = mockPresideObjectService
			, presideContentRenderer = mockRendererService
			, coldboxRenderer        = mockRendererPlugin
			, cacheProvider          = _getCachebox().getDefaultCache()
		);
	}

}