component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		mockPresideObjectService = getMockbox().createEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		mockLogger               = _getTestLogger();

		mockPresideObjectService.$( "objectExists" ).$results( true );
		testDirs = [ "/tests/resources/pageTypes/dir1", "/tests/resources/pageTypes/dir2", "/tests/resources/pageTypes/dir3" ];
	}

// TESTS
	function test01_listPageTypes_shouldReturnEmptyArray_whenNoPageTypesDiscovered() {
		super.assertEquals( [], _getPageTypesSvc().listPageTypes() );
	}

	function test02_listPageTypes_shouldReturnAnArrayOfTypesThatHaveBeenAutoDiscoveredThroughTheConfiguredDirectories() {
		var expected     = [ "blog", "casestudy", "event", "page", "some_page_type", "teammember" ];
		var pageTypes    = _getPageTypesSvc( testDirs ).listPageTypes();
		var ids          = [];

		for( var pType in pageTypes ){
			ArrayAppend( ids, pType.getid() );
		}

		ids.sort( "textnocase" );
		super.assertEquals( expected, ids );
	}

	function test03_pageTypeExists_shouldReturnFalse_whenNoPageTypesDiscovered() {
		super.assertFalse( _getPageTypesSvc().pageTypeExists( "somepagetype" ) );
	}

	function test04_pageTypeExists_shouldReturnTrue_whenPageTypeExists() {
		super.assert( _getPageTypesSvc( testDirs ).pageTypeExists( "casestudy" ) );
		super.assert( _getPageTypesSvc( testDirs ).pageTypeExists( "teammember" ) );
	}

	function test05_getPageType_shouldReturnPageTypeBeanWithConventionBasedIdNameDescriptionViewletAndFormNames() {
		var pageTypeBean = _getPageTypesSvc( testDirs ).getPageType( "casestudy" );

		super.assertEquals( "casestudy"                       , pageTypeBean.getId()          );
		super.assertEquals( "page-types.casestudy:name"       , pageTypeBean.getName()        );
		super.assertEquals( "page-types.casestudy:description", pageTypeBean.getDescription() );
		super.assertEquals( "page-types.casestudy"            , pageTypeBean.getViewlet()     );
		super.assertEquals( "page-types.casestudy.add"        , pageTypeBean.getAddForm()     );
		super.assertEquals( "page-types.casestudy.edit"       , pageTypeBean.getEditForm()    );
	}

	function test06_hasHandler_shouldReturnFalse_whenPageTypeDoesNotHaveAHandler() {
		var pageTypeBean = _getPageTypesSvc( testDirs ).getPageType( "caseStudy" );

		super.assertFalse( pageTypeBean.hasHandler() );
	}

	function test07_hasHandler_shouldReturnFalse_whenPageTypeHasAHandler() {
		var pageTypeBean = _getPageTypesSvc( testDirs ).getPageType( "event" );

		super.assert( pageTypeBean.hasHandler() );
	}

	function test08_getPageType_shouldThrowInformativeError_whenPageTypeDoesNotExist(){
		var errorThrown = false;

		try {
			_getPageTypesSvc( testDirs ).getPageType( "i-do-not-exist" );

		} catch ( "PageTypesService.missingPageType" e ) {
			super.assertEquals( "The template, [i-do-not-exist], was not registered with the Preside page types system", e.message );
			errorThrown = true;
		}

		super.assert( errorThrown, "No informative error was thrown" );
	}

	function test09_listLayouts_shouldReturnSingleDefaultLayout_whenOnlyASingleViewExistsForTemplate(){
		var layouts = _getPageTypesSvc( testDirs ).getPageType( "blog" ).listLayouts();

		super.assertEquals( [ "index" ], layouts );
	}

	function test10_listLayouts_shouldReturnUniqueListOfLayoutsForTemplate_whenMultipleViewsArePresentForThePageType(){
		var layouts = _getPageTypesSvc( testDirs ).getPageType( "event" ).listLayouts();

		layouts.sort( "textnocase" );

		super.assertEquals( [ "course", "index", "special" ], layouts );
	}

// private helpers
	private any function _getPageTypesSvc( array autoDiscoverDirectories=[] ) output=false {
		return new preside.system.services.pageTypes.PageTypesService(
			  presideObjectService    = mockPresideObjectService
			, logger                  = mockLogger
			, autoDiscoverDirectories = arguments.autoDiscoverDirectories
		);
	}


}