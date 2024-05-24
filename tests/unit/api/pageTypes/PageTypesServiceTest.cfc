component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
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

		super.assertEquals( "casestudy"                                          , pageTypeBean.getId()                 );
		super.assertEquals( "page-types.casestudy:name"                          , pageTypeBean.getName()               );
		super.assertEquals( "page-types.casestudy:description"                   , pageTypeBean.getDescription()        );
		super.assertEquals( "page-types.casestudy.index"                         , pageTypeBean.getViewlet()            );
		super.assertEquals( "page-types.casestudy.add"                           , pageTypeBean.getAddForm()            );
		super.assertEquals( "page-types.casestudy.edit"                          , pageTypeBean.getEditForm()           );
		super.assertEquals( "casestudy,blog,event,some_page_type,page,teammember", pageTypeBean.getAllowedChildTypes()  );
		super.assertEquals( "*"                                                  , pageTypeBean.getAllowedParentTypes() );
	}

	function test06_hasHandler_shouldReturnFalse_whenPageTypeDoesNotHaveAHandler() {
		var pageTypeBean = _getPageTypesSvc( testDirs ).getPageType( "caseStudy" );

		super.assertFalse( pageTypeBean.hasHandler() );
	}

	function test07_hasHandler_shouldReturnTrue_whenPageTypeHasAHandler() {
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

	function test11_getPageType_shouldReturnAllowedChildAndParentPageTypes_whenTheyAreDefinedInPresideObjectAttributes() {
		var pageTypeBean = _getPageTypesSvc( testDirs ).getPageType( "event" );

		super.assertEquals( "none", pageTypeBean.getAllowedChildTypes()  );
		super.assertEquals( "casestudy", pageTypeBean.getAllowedParentTypes() );
	}

	function test12_listPageTypes_shouldExcludePageTypesThatHaveAnExplicitAllowedParentsListThatDoesNotMatchTheGivenParent() {
		var expected     = [ "blog", "casestudy", "page", "some_page_type", "teammember" ];
		var pageTypes    = _getPageTypesSvc( testDirs ).listPageTypes( allowedBeneathParent="some_page_type" );
		var ids          = [];

		for( var pType in pageTypes ){
			ArrayAppend( ids, pType.getid() );
		}

		ids.sort( "textnocase" );
		super.assertEquals( expected, ids );
	}

	function test13_listPageTypes_shouldOnlyAllowExplicitListOfChildTypes_whenParentHasExplicitChildList() {
		var expected     = [ "page", "teammember" ];
		var pageTypes    = _getPageTypesSvc( testDirs ).listPageTypes( allowedBeneathParent="blog" );
		var ids          = [];

		for( var pType in pageTypes ){
			ArrayAppend( ids, pType.getid() );
		}

		ids.sort( "textnocase" );
		super.assertEquals( expected, ids );
	}

	function test12_listPageTypes_shouldReturnEmptyArrayWhenParentDoesNotAllowChildren() {
		var pageTypes  = _getPageTypesSvc( testDirs ).listPageTypes( allowedBeneathParent="event" );

		super.assertEquals( [], pageTypes );
	}

	function test13_listPageTypes_shouldNotListPageTypesThatAreDeclaredInNonActiveSiteTemplates() {
		var pageTypes  = _getPageTypesSvc( [ "/tests/resources/pageTypes/site-templates/template1" ] ).listPageTypes();

		super.assertEquals( [], pageTypes );
	}

	function test14_listPageTypes_shouldListPageTypesThatAreDeclaredInTheActiveSiteTemplate() {
		var pageTypes  = _getPageTypesSvc( [ "/tests/resources/pageTypes/site-templates/template1" ], "template1" ).listPageTypes();

		super.assertEquals( 1, pageTypes.len() );
		super.assertEquals( "event", pageTypes[1].getId() );
	}

	function test15_isSystemPageType_shouldReturnTrue_whenPageTypeCfcHasSystemPageTypeAttribute() {
		var pageTypesService  = _getPageTypesSvc( [ "/tests/resources/pageTypes/dir1/" ] );

		super.assert( pageTypesService.isSystemPageType( "some_page_type" ) );
	}


// private helpers
	private any function _getPageTypesSvc( array autoDiscoverDirectories=[], string activeSiteTemplate="" ) output=false {
		var objDirs     = [];

		mockSiteService = getMockBox().createMock( "preside.system.services.siteTree.SiteService" );
		mockSiteService.$( "getActiveSiteTemplate", arguments.activeSiteTemplate );

		for( dir in autoDiscoverDirectories ){
			objDirs.append( dir & "/preside-objects" );
		}

		return new preside.system.services.pageTypes.PageTypesService(
			  presideObjectService    = _getPresideObjectService( objectDirectories=objDirs )
			, autoDiscoverDirectories = arguments.autoDiscoverDirectories
			, siteService             = mockSiteService
		);
	}


}