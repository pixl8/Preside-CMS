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
	function test01_viewExists_shouldReturnTrue_whenBothGivenObjectAndViewExist() output=false {
		var svc = _getPresideObjectViewService( [ viewFolders[1] ] );

		super.assert( svc.viewExists( object="object_b", view="full" ) );
	}

	function test02_viewExists_shouldReturnFalse_whenNoViewsExistForTheObject() output=false {
		var svc = _getPresideObjectViewService( [ viewFolders[1] ] );

		super.assertFalse( svc.viewExists( object="i_do_not_exist", view="index" ) );
	}

	function test03_viewExists_shouldReturnFalse_whenTheSpecifiedViewDoesNotExistForTheObject() output=false {
		var svc = _getPresideObjectViewService( [ viewFolders[1], viewFolders[2] ] );

		super.assertFalse( svc.viewExists( object="object_b", view="non-existent" ) );
	}

	function test04_viewExists_shouldReturnTrue_whenNoViewSuppliedButADefaultIndexViewExistsForTheObject() output=false {
		var svc = _getPresideObjectViewService( viewFolders );

		super.assert( svc.viewExists( object="object_b" ) );
	}

	function test05_viewExists_shouldReturnFalse_whenNoViewSuppliedAndNoDefaultIndexViewExistsForTheObject() output=false {
		var svc = _getPresideObjectViewService( [ viewFolders[1] ] );

		super.assertFalse( svc.viewExists( object="object_e" ) );
	}

	function test06_renderView_shouldFetchDataFromPresideObjectServiceWithFieldListDerivedFromView() output=false {
		var svc = _getPresideObjectViewService( [ viewFolders[1] ] );
		var log = "";
		var expectedArguments = {
			  objectName   = "object_b"
			, selectFields = [ "object_b.label as label", "object_b.datecreated as datecreated", "object_b.id as _id" ]
		};

		mockPresideObjectService.$( "selectData", QueryNew('') );
		mockRendererPlugin.$( "renderView", "" );

		svc.renderView( object = "object_b" );

		log = mockPresideObjectService.$callLog().selectData;

		super.assertEquals( 1, log.len(), "Expected a single call to selectData(), instead [#log.len()#] were made" );

		super.assertEquals( expectedArguments.objectName  , log[1].objectName   ?: "" );
		super.assertEquals( expectedArguments.selectFields, log[1].selectFields ?: "" );
	}

	function test06_01_renderView_shouldFetchDataFromPresideObjectServiceWithFieldListDerivedFromOverridedView() output=false {
		var svc = _getPresideObjectViewService( [ viewFolders[1], viewFolders[2] ] );
		var log = "";
		var expectedArguments = {
			  objectName   = "object_b"
			, selectFields = [ "label as title", "datecreated as createdDate", "object_b.id as _id" ]
		};

		mockPresideObjectService.$( "selectData", QueryNew('') );
		mockRendererPlugin.$( "renderView", "" );

		svc.renderView( object = "object_b" );

		log = mockPresideObjectService.$callLog().selectData;

		super.assertEquals( 1, log.len(), "Expected a single call to selectData(), instead [#log.len()#] were made" );

		super.assertEquals( expectedArguments.objectName  , log[1].objectName   ?: "" );
		super.assertEquals( expectedArguments.selectFields, log[1].selectFields ?: "" );
	}

	function test07_renderView_shouldForwardAllRelevantArgumentsPassedToTheSelectDataCall_soThatWeCanPassInFiltersAndSortOrdersEtc() output=false {
		var svc = _getPresideObjectViewService( [ viewFolders[1], viewFolders[2] ] );
		var log = "";
		var passedArgs = {
			  object = "object_b"
			, view   = "full"
			, sortBy = "this"
			, filter = "fubar = :this"
			, filterArgs = { this = "is a test" }
			, anything = "really"
		}
		var expectedArguments = {
			  objectName   = "object_b"
			, selectFields = [ "label as title", "object_e.label as category", "object_b.datecreated as datecreated", "object_b.id as _id" ]
			, sortBy = "this"
			, filter = "fubar = :this"
			, filterArgs = { this = "is a test" }
			, anything = "really"
			, pageView = false
		};
		var actualForwardedArgs = "";
		var expectedArgumemntNames = StructKeyArray( expectedArguments );
		var actualForwardedArgNames = "";

		mockPresideObjectService.$( "selectData", QueryNew('') );
		mockRendererPlugin.$( "renderView", "" );

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

	function test08_renderView_shouldRenderEachRecordIndividually() output=false {
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

		actualResult = svc.renderView(
			  object = "object_b"
			, view   = "full"
		);

		super.assertEquals( expectedResult, actualResult );

		log = mockRendererPlugin.$callLog().renderView;

		super.assertEquals( mockData.recordCount, log.len() );

		for( var i=1; i lte mockData.recordCount; i++ ){
			super.assertEquals( "/preside-objects/object_b/full", log[i].view );
			super.assertEquals( 4, StructCount( log[i].args ) );
			super.assertEquals( mockData.this[i], log[i].args.this );
			super.assertEquals( mockData.is[i]  , log[i].args.is   );
			super.assertEquals( mockData.some[i], log[i].args.some );
			super.assertEquals( mockData.data[i], log[i].args.data );
		}
	}

	function test09_renderView_shouldThrowInformativeError_whenObjectViewDoesNotExist() output=false {
		var svc         = _getPresideObjectViewService( [ viewFolders[1], viewFolders[2] ] );
		var errorThrown = false;

		try {
			svc.renderView( object="meh", view="boohoo" );
		} catch( "presideObjectViewService.missingView" e ) {
			super.assertEquals( "Object view not found for object named, [meh], and view named, [boohoo]", e.message );
			errorThrown = true;
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

// private utility
	private any function _getPresideObjectViewService( folders ) output=false {
		mockPresideObjectService = createMock( "preside.system.api.presideObjects.presideObjectViewService" );
		mockRendererService      = createMock( "preside.system.api.rendering.ContentRendererService" );
		mockRendererPlugin       = createMock( "preside.system.coldboxModifications.plugins.Renderer" );

		return new preside.system.api.presideObjects.presideObjectViewService(
			  viewDirectories        = folders
			, presideObjectService   = mockPresideObjectService
			, presideContentRenderer = mockRendererService
			, coldboxRenderer        = mockRendererPlugin
		);
	}

}