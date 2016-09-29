<cfcomponent output="false" extends="tests.resources.HelperObjects.PresideTestCase">

<!---

	Commenting out test suite while we figure out a better way to test this stuff. Probably best done by mocking
	out all the DB calls, etc. I.e. Make it a unit test rather than an integration test.


	<cffunction name="setup" access="public" returntype="any" output="false">
		<cfscript>
			_wipeData();
			_setupDummyTreeData();

			_login();
		</cfscript>
	</cffunction>

	<cffunction name="beforeTests" access="public" returntype="any" output="false">
		<cfscript>
			mockColdbox      = getMockbox().createEmptyMock( "preside.system.coldboxModifications.Controller" );
			mockColdboxEvent = getMockbox().createStub();

			mockColdboxEvent.$( "isAdminUser"   , true );
			mockColdboxEvent.$( "getAdminUserId", ""   );
			mockColdboxEvent.$( "getSite"       , {}   );

			mockColdbox.$( "getRequestContext", mockColdboxEvent );

			poService   = _getPresideObjectService( forceNewInstance=true, coldbox=mockColdbox );
			var logger      = _getTestLogger();
			var siteService = getMockBox().createEmptyMock( "preside.system.services.siteTree.SiteService" );
			var emailService = getMockBox().createEmptyMock( "preside.system.services.email.EmailService" );
			var pageTypesService = new preside.system.services.pageTypes.PageTypesService( logger=logger, presideObjectService=poService, autoDiscoverDirectories=[ "/preside/system" ], siteService=SiteService );

			loginService = new preside.system.services.admin.loginService(
				  logger               = logger
				, presideObjectService = poService
				, sessionStorage       = new coldbox.system.plugins.SessionStorage()
				, bCryptService        = _getBCrypt()
				, systemUserList       = "sysadmin"
				, emailService         = emailService
				, userDao              = poService.getObject( "security_user" )
			);

			siteTreeService = new preside.system.services.sitetree.SiteTreeService(
				  logger               = logger
				, presideObjectService = poService
				, loginService         = loginService
				, pageTypesService     = pageTypesService
			);

			_emptyDatabase();
			_dbSync();
		</cfscript>
	</cffunction>

	<cffunction name="test01_addPage_shouldAutomaticallyCalculateHierarchyHelpersForRootNode" returntype="void">
		<cfscript>
			var treeSvc = siteTreeService;
			var pageId = treeSvc.addPage(
				  title         = "Home"
				, slug          = "home"
				, page_type = "homepage"
			);
			var hierarchyId = _getHierarchyIdForPage( pageId, treeSvc );
			var expected = {
				  id                    = pageId
				, title                 = "Home"
				, slug                      = "home"
				, page_type             = "homepage"
				, sort_order                = 1
				, active                    = 0
				, created_by                = dummyUser
				, updated_by                = dummyUser
				, _hierarchy_sort_order     = "/1/"
				, _hierarchy_lineage        = "/"
				, _hierarchy_child_selector = "/#hierarchyId#/%"
				, _hierarchy_depth          = 0
				, _hierarchy_slug           = "/home/"
			};
			var expectedNulls = [ "parent_page", "embargo_date", "expiry_date", "author" ,"browser_title","keywords","description" ];
			var createdPage = poService.selectData( objectName="page", filter={ id = pageId } );
			var field = "";

			super.assert( createdPage.recordCount, "No record was created" );
			for( field in expected ){
				super.assertEquals( expected[field], createdPage[field][1], "[#field#] value not as expected. Expected [#expected[field]#] bu received [#createdPage[field][1]#]" );
			}
			for( field in expectedNulls ){
				super.assert( IsNull(createdPage[field][1]) or not Len( createdPage[field][1] ), "Expected [#field#] to be null, it was not." );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test02_addPage_shouldAutomaticallyCalculateHierarchyHelpersForChildNodes" returntype="void">
		<cfscript>
			var treeSvc = siteTreeService;
			var rootPageId = treeSvc.addPage(
				  title     = "Home"
				, slug      = "home"
				, page_type = "homepage"
			);
			var rootHierarchyid = _getHierarchyIdForPage( rootPageId, treeSvc );
			var childPageIds = [];
			var expected     = "";
			var createdPages = "";
			var page = "";

			for( var i=1; i lte 5; i++ ) {
				childPageIds[i] = treeSvc.addPage(
					  parent_page   = rootPageId
					, title     = "Child #i#"
					, slug          = "child-#i#"
					, page_type = "standard_page"
				);
			}

			createdPages = poService.selectData( objectName="page", filter={ id = childPageIds }, orderBy="_hierarchy_sort_order" );

			super.assertEquals( 5, createdPages.recordCount, "Expected 5 pages to be created, instead #createdPages.recordCount# were reported." )
			for( var i=1; i lte 5; i++ ){
				page = treeSvc.getPage( id=childPageIds[i], includeTrash=true );
				expected = {
					  id                    = childPageIds[i]
					, title                 = "Child #i#"
					, slug                      = "child-#i#"
					, page_type             = "standard_page"
					, sort_order                = i
					, active                    = 0
					, created_by                = dummyUser
					, updated_by                = dummyUser
					, _hierarchy_sort_order     = "/1/#i#/"
					, _hierarchy_lineage        = "/#rootHierarchyid#/"
					, _hierarchy_child_selector = "/#rootHierarchyid#/#page._hierarchy_id#/%"
					, _hierarchy_depth          = 1
					, _hierarchy_slug           = "/home/child-#i#/"
					, parent_page               = rootPageId
				};

				for( field in expected ){
					super.assertEquals( expected[field], createdPages[field][i], "[#field#] value not as expected for record #i#. Expected [#expected[field]#] bu received [#createdPages[field][i]#]" );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="test03_addPage_shouldAllowTheSettingOfAnyNonRequiredFieldsThroughTheArgumentsScopeThatExistInTheComponentDefinition" returntype="void">
		<cfscript>
			var treeSvc = siteTreeService;
			var pageId = treeSvc.addPage(
				  title                     = "some page"
				, slug                      = "some-slug"
				, page_type                 = "standard_page"
				, active                    = 1
				, author                    = "test author"
				, browser_title             = "test browser_title"
				, keywords                  = "test keywords"
				, description               = "test description"
				, any_old_column            = "blah" // should be ignored (does not exist in component)
				, _hierarchy_sort_order     = "test" // should be ignored (because auto generated)
				, _hierarchy_lineage        = "test" // should be ignored (because auto generated)
				, _hierarchy_child_selector = "test" // should be ignored (because auto generated)
				, _hierarchy_slug           = "test" // should be ignored (because auto generated)
				, _hierarchy_depth          = 45983  // should be ignored (because auto generated)
				, sort_order                = 4545   // should be ignored (because auto generated)
			);
			var hierarchyId = _getHierarchyIdForPage( pageId, treeSvc );
			var expected = {
				  id                        = pageId
				, title                     = "some page"
				, slug                      = "some-slug"
				, page_type                 = "standard_page"
				, sort_order                = 1
				, active                    = 1
				, created_by                = dummyUser
				, updated_by                = dummyUser
				, author                    = "test author"
				, browser_title             = "test browser_title"
				, keywords                  = "test keywords"
				, description               = "test description"
				, _hierarchy_sort_order     = "/1/"
				, _hierarchy_lineage        = "/"
				, _hierarchy_child_selector = "/#hierarchyId#/%"
				, _hierarchy_depth          = 0
				, _hierarchy_slug           = "/some-slug/"
			};
			var createdPage = poService.selectData( objectName="page", filter={ id = pageId } );
			var field = "";

			super.assert( createdPage.recordCount, "No record was created" );
			for( field in expected ){
				super.assertEquals( expected[field], createdPage[field][1], "[#field#] value not as expected" );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test04_addPage_shouldThrowInformativeError_whenParentPageDoesNotExist" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var errorThrown = false;
			var dummyId     = 2398493;

			try {
				treeSvc.addPage(
					  title       = "some page"
					, slug        = "some-slug"
					, page_type   = "standard_page"
					, parent_page = dummyId
				);

			} catch ( "SiteTreeService.MissingParent" e ) {
				super.assertEquals( "Error when adding site tree page. Parent page with id, [#dummyId#], was not found.", e.message );
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test05_editPage_shouldAllowYouToUpdateArbitraryFieldsOnThePage" returntype="void">
		<cfscript>
			var treeSvc = siteTreeService;
			var pageId = treeSvc.addPage(
				  title     = "Home"
				, slug      = "home"
				, page_type = "homepage"
			);
			var updated = treeSvc.editPage(
				  id = pageId
				, embargo_date = "2050-08-14"
				, expiry_date  = "2050-08-15"
				, browser_title = "test title"
			);
			var createdPage = poService.selectData( objectName="page", filter={ id = pageId } );
			var expected = {
				  browser_title = "test title"
				, embargo_date  = "{ts '2050-08-14 00:00:00'}"
				, expiry_date   = "{ts '2050-08-15 00:00:00'}"
			};
			var field = "";

			super.assert( updated, "editPage did not inform us that it updated any record. Likely a problem with the test." );
			super.assert( createdPage.recordCount, "Could not find the created record that was subsequently updated. Likely a problem with the test." );

			for( field in expected ){
				super.assertEquals( expected[ field ], createdPage[ field ][ 1 ] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test06_editPage_shouldAdjustChildPageHierarchyHelpers_whenParentPageSortOrderChanges" returntype="void">
		<cfscript>
			var treeSvc      = siteTreeService;
			var dummyPages   = _createADummySiteTreeWithAFewLevelsOfDepth();
			var newSortOrder = 3459;
			var sortOrder    = "";
			var updated      = treeSvc.editPage(
				  id     = dummyPages[1].children[3].id
				, sort_order = newSortOrder
			);
			var allRows    = poService.selectData( objectName="page", selectFields=["_hierarchy_sort_order"], orderBy="_hierarchy_sort_order" );
			var expectedSortOrders = [ "/1/" ];

			for( var i=1; i lte 5; i++ ) {
				sortOrder = i eq 3 ? newSortOrder : i;

				ArrayAppend( expectedSortOrders, "/1/#sortOrder#/" );
				for( var n=1; n lte 5; n++ ){
					ArrayAppend( expectedSortOrders, "/1/#sortOrder#/#n#/" );
					for( var x=1; x lte 5; x++ ){
						ArrayAppend( expectedSortOrders, "/1/#sortOrder#/#n#/#x#/" );
					}
				}
			}

			super.assertEquals( ArrayLen( expectedSortOrders ), allRows.recordCount, "Problem with the test setup - do not have the expected number of records in the database" );

			for( var i=1; i lte ArrayLen( expectedSortOrders ); i++ ){
				super.assertEquals( expectedSortOrders[i], allRows._hierarchy_sort_order[i] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test07_editPage_shouldAdjutChildSlugs_whenParentSlugChanges" returntype="void">
		<cfscript>
			var treeSvc      = siteTreeService;
			var dummyPages   = _createADummySiteTreeWithAFewLevelsOfDepth();
			var newSlug      = "new-slug-that-is-a-test";
			var slug         = "";
			var updated      = treeSvc.editPage(
				  id = dummyPages[1].children[2].id
				, slug   = newSlug
			);
			var allRows    = poService.selectData( objectName="page", selectFields=["_hierarchy_slug"], orderBy="_hierarchy_sort_order" );
			var expectedSlugs = [ "/home/" ];

			for( var i=1; i lte 5; i++ ) {
				slug = i eq 2 ? newSlug : "child-#i#";

				ArrayAppend( expectedSlugs, "/home/#slug#/" );
				for( var n=1; n lte 5; n++ ){
					ArrayAppend( expectedSlugs, "/home/#slug#/child-#i#-#n#/" );
					for( var x=1; x lte 5; x++ ){
						ArrayAppend( expectedSlugs, "/home/#slug#/child-#i#-#n#/child-#i#-#n#-#x#/" );
					}
				}
			}

			super.assertEquals( ArrayLen( expectedSlugs ), allRows.recordCount, "Problem with the test setup - do not have the expected number of records in the database" );

			for( var i=1; i lte ArrayLen( expectedSlugs ); i++ ){
				super.assertEquals( expectedSlugs[i], allRows._hierarchy_slug[i] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test08_editPage_shouldAdjustChildLineageSortOrderSlugAndDepth_whenParentsParentChanges" returntype="void">
		<cfscript>
			var treeSvc    = siteTreeService;
			var dummyPages = _createADummySiteTreeWithAFewLevelsOfDepth( includeHierarchyIds = true );
			var updated    = treeSvc.editPage(
				  id      = dummyPages[1].children[5].id
				, parent_page = dummyPages[1].children[4].id
			);
			var allRows    = poService.selectData( objectName="page", orderBy="_hierarchy_sort_order" );
			var expected   = [ { lineage="/", selector="/#dummyPages[1]._hierarchy_id#/%", sortorder="/1/", slug="/home/", depth=0 } ];

			// MODEL THE EXPECTED NEW SORT ORDER OF DATA (a bit of a PITA!)
			for( var i=1; i lte 4; i++ ) {
				ArrayAppend( expected, {
					  lineage   = "/#dummyPages[1]._hierarchy_id#/"
					, selector  = "/#dummyPages[1]._hierarchy_id#/#dummyPages[1].children[i]._hierarchy_id#/%"
					, sortorder = "/1/#i#/"
					, slug      = "/home/child-#i#/"
					, depth     = 1
				} );

				for( var n=1; n lte 5; n++ ){
					ArrayAppend( expected, {
						  lineage   = "/#dummyPages[1]._hierarchy_id#/#dummyPages[1].children[i]._hierarchy_id#/"
						, selector  = "/#dummyPages[1]._hierarchy_id#/#dummyPages[1].children[i]._hierarchy_id#/#dummyPages[1].children[i].children[n]._hierarchy_id#/%"
						, sortorder = "/1/#i#/#n#/"
						, slug      = "/home/child-#i#/child-#i#-#n#/"
						, depth     = 2
					} );

					for( var x=1; x lte 5; x++ ){
						ArrayAppend( expected, {
							  lineage   = "/#dummyPages[1]._hierarchy_id#/#dummyPages[1].children[i]._hierarchy_id#/#dummyPages[1].children[i].children[n]._hierarchy_id#/"
							, selector  = "/#dummyPages[1]._hierarchy_id#/#dummyPages[1].children[i]._hierarchy_id#/#dummyPages[1].children[i].children[n]._hierarchy_id#/#dummyPages[1].children[i].children[n].children[x]._hierarchy_id#/%"
							, sortorder = "/1/#i#/#n#/#x#/"
							, slug      = "/home/child-#i#/child-#i#-#n#/child-#i#-#n#-#x#/"
							, depth     = 3
						} );
					}
				}
			}

			ArrayAppend( expected, {
				  lineage   = "/#dummyPages[1]._hierarchy_id#/#dummyPages[1].children[4]._hierarchy_id#/"
				, selector  = "/#dummyPages[1]._hierarchy_id#/#dummyPages[1].children[4]._hierarchy_id#/#dummyPages[1].children[5]._hierarchy_id#/%"
				, sortorder = "/1/4/6/"
				, slug      = "/home/child-4/child-5/"
				, depth     = 2
			} );

			for( var i=1; i lte 5; i++ ) {
				ArrayAppend( expected, {
					  lineage   = "/#dummyPages[1]._hierarchy_id#/#dummyPages[1].children[4]._hierarchy_id#/#dummyPages[1].children[5]._hierarchy_id#/"
					, selector  = "/#dummyPages[1]._hierarchy_id#/#dummyPages[1].children[4]._hierarchy_id#/#dummyPages[1].children[5]._hierarchy_id#/#dummyPages[1].children[5].children[i]._hierarchy_id#/%"
					, sortorder = "/1/4/6/#i#/"
					, slug      = "/home/child-4/child-5/child-5-#i#/"
					, depth     = 3
				} );

				for( var n=1; n lte 5; n++ ){
					ArrayAppend( expected, {
						  lineage   = "/#dummyPages[1]._hierarchy_id#/#dummyPages[1].children[4]._hierarchy_id#/#dummyPages[1].children[5]._hierarchy_id#/#dummyPages[1].children[5].children[i]._hierarchy_id#/"
						, selector  = "/#dummyPages[1]._hierarchy_id#/#dummyPages[1].children[4]._hierarchy_id#/#dummyPages[1].children[5]._hierarchy_id#/#dummyPages[1].children[5].children[i]._hierarchy_id#/#dummyPages[1].children[5].children[i].children[n]._hierarchy_id#/%"
						, sortorder = "/1/4/6/#i#/#n#/"
						, slug      = "/home/child-4/child-5/child-5-#i#/child-5-#i#-#n#/"
						, depth     = 4
					} );
				}
			}

			// FINALLY, THE ASSERTIONS!
			super.assertEquals( ArrayLen( expected ), allRows.recordCount, "Problem with the test setup - do not have the expected number of records in the database" );

			for( var i=1; i lte ArrayLen( expected ); i++ ){
				super.assertEquals( expected[i].lineage  , allRows._hierarchy_lineage[i]        );
				super.assertEquals( expected[i].selector , allRows._hierarchy_child_selector[i] );
				super.assertEquals( expected[i].sortorder, allRows._hierarchy_sort_order[i]     );
				super.assertEquals( expected[i].slug     , allRows._hierarchy_slug[i]           );
				super.assertEquals( expected[i].depth    , allRows._hierarchy_depth[i]          );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test09_editPage_shouldAdjustChildLineageSortOrderSlugAndDepth_whenParentsParentANDSlugChanges" returntype="void">
		<cfscript>
			var treeSvc    = siteTreeService;
			var dummyPages = _createADummySiteTreeWithAFewLevelsOfDepth( includeHierarchyIds = true );
			var newSlug    = "i-changed-too";
			var updated    = treeSvc.editPage(
				  id          = dummyPages[1].children[1].id
				, parent_page = dummyPages[1].children[2].children[1].id
				, slug        = newSlug
			);
			var expected    = [];
			var newParent   = poService.selectData( objectName="page", filter={ id=dummyPages[1].children[2].children[1].id } );
			var newChildren = poService.selectData(
				  objectName="page"
				, filter="_hierarchy_lineage like :_hierarchy_lineage or id = :id"
				, filterParams={ id=dummyPages[1].children[1].id, _hierarchy_lineage=newParent._hierarchy_lineage & newParent._hierarchy_id & "/" & dummyPages[1].children[1]._hierarchy_id & "/%" }
				, orderBy = "_hierarchy_sort_order"
			);

			ArrayAppend( expected, {
				  lineage   = newParent._hierarchy_lineage & newParent._hierarchy_id & "/"
				, selector  = newParent._hierarchy_lineage & newParent._hierarchy_id & "/" & dummyPages[1].children[1]._hierarchy_id & "/%"
				, sortorder = "/1/2/1/6/"
				, slug      = "/home/child-2/child-2-1/#newSlug#/"
				, depth     = 3
			} );

			for( var i=1; i lte 5; i++ ) {
				ArrayAppend( expected, {
					  lineage   = newParent._hierarchy_lineage & newParent._hierarchy_id & "/" & dummyPages[1].children[1]._hierarchy_id & "/"
					, selector  = newParent._hierarchy_lineage & newParent._hierarchy_id & "/" & dummyPages[1].children[1]._hierarchy_id & "/" & dummyPages[1].children[1].children[i]._hierarchy_id & "/%"
					, sortorder = "/1/2/1/6/#i#/"
					, slug      = "/home/child-2/child-2-1/#newSlug#/child-1-#i#/"
					, depth     = 4
				} );

				for( var n=1; n lte 5; n++ ){
					ArrayAppend( expected, {
						  lineage   = newParent._hierarchy_lineage & newParent._hierarchy_id & "/" & dummyPages[1].children[1]._hierarchy_id & "/" & dummyPages[1].children[1].children[i]._hierarchy_id & "/"
						, selector  = newParent._hierarchy_lineage & newParent._hierarchy_id & "/" & dummyPages[1].children[1]._hierarchy_id & "/" & dummyPages[1].children[1].children[i]._hierarchy_id & "/" & dummyPages[1].children[1].children[i].children[n]._hierarchy_id & "/%"
						, sortorder = "/1/2/1/6/#i#/#n#/"
						, slug      = "/home/child-2/child-2-1/#newSlug#/child-1-#i#/child-1-#i#-#n#/"
						, depth     = 5
					} );
				}
			}

			// FINALLY, THE ASSERTIONS!
			super.assertEquals( ArrayLen( expected ), newChildren.recordCount, "Problem with the test setup - do not have the expected number of records in the database" );

			for( var i=1; i lte ArrayLen( expected ); i++ ){
				super.assertEquals( expected[i].lineage  , newChildren._hierarchy_lineage[i]        );
				super.assertEquals( expected[i].selector , newChildren._hierarchy_child_selector[i] );
				super.assertEquals( expected[i].sortorder, newChildren._hierarchy_sort_order[i]     );
				super.assertEquals( expected[i].slug     , newChildren._hierarchy_slug[i]           );
				super.assertEquals( expected[i].depth    , newChildren._hierarchy_depth[i]          );
			}
		</cfscript>
	</cffunction>

	<cffunction name="test10_trashPage_shouldSendPage_andAllItsChildren_toTheRecycleBin" returntype="void">
		<cfscript>
			var treeSvc                  = siteTreeService;
			var dummyPages               = _createADummySiteTreeWithAFewLevelsOfDepth( includeHierarchyIds=true );
			var recycledPages            = "";
			var expectedTrashCount       = 31;
			var pagesThatShouldBeDeleted = "";
			var expected                 = [];
			var page                     = dummyPages[1].children[3];

			ArrayAppend( expected, { sort_order=2, _hierarchy_depth = 0, _hierarchy_lineage="/", _hierarchy_child_selector="/#page._hierarchy_id#/%", _hierarchy_sort_order="/2/" } );

			for( var i=1; i lte 5; i++ ) {
				ArrayAppend( expected, { sort_order=i, _hierarchy_depth = 1, _hierarchy_lineage="/#page._hierarchy_id#/", _hierarchy_child_selector="/#page._hierarchy_id#/#page.children[i]._hierarchy_id#/%", _hierarchy_sort_order="/2/#i#/" } );

				for( var n=1; n lte 5; n++ ) {
					ArrayAppend( expected, { sort_order=n, _hierarchy_depth = 2, _hierarchy_lineage="/#page._hierarchy_id#/#page.children[i]._hierarchy_id#/", _hierarchy_child_selector="/#page._hierarchy_id#/#page.children[i]._hierarchy_id#/#page.children[i].children[n]._hierarchy_id#/%", _hierarchy_sort_order="/2/#i#/#n#/" } );
				}
			}

			treeSvc.trashPage( dummyPages[1].children[3].id );

			recycledPages            = poService.selectData( objectName="page", filter={ trashed = true }, orderBy="_hierarchy_sort_order", useCcahe=false );
			pagesThatShouldBeDeleted = poService.selectData(
				  objectName   = "page"
				, orderBy      = "_hierarchy_sort_order"
				, filter       = "trashed = '0' and ( _hierarchy_lineage like :_hierarchy_lineage or id = :id )"
				, filterParams = { id = dummyPages[1].children[3].id, _hierarchy_lineage="/#dummyPages[1]._hierarchy_id#/#dummyPages[1].children[3]._hierarchy_id#/%" }
				, useCache     = false
			);

			super.assertEquals( expectedTrashCount, recycledPages.recordCount );
			super.assertEquals( 0                 , pagesThatShouldBeDeleted.recordCount, "Pages were not deleted from main site tree" );

			for( var i=1; i lte ArrayLen( expected ); i++ ) {
				for( field in expected[i] ) {
					super.assertEquals( expected[i][field], recycledPages[field][i], "#field# was not the same for row #i#" );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="test12_restorePage_shouldRestorePage_andItsChildren_toSpecifiedParent" returntype="void">
		<cfscript>
			var treeSvc          = siteTreeService;
			var dummyPages       = _createADummySiteTreeWithAFewLevelsOfDepth( includeHierarchyIds=true );
			var page             = dummyPages[1].children[2];
			var expected         = [];
			var recycledBefore   = "";
			var recycledAfter    = "";
			var nRecordsRestored = "";
			var restoredPages    = "";

			// SETUP THE DUMMY DATA AND EXPECTED RESULTS
			treeSvc.trashPage( page.id );

			recycledBefore = poService.selectData(
				  objectName   = "page"
				, selectFields = [ "Count(*) as nPages" ]
				, filter       = { trashed = 1 }
				, useCache     = false
			);

			ArrayAppend( expected, { sort_order=6, _hierarchy_slug="/home/new-slug/", _hierarchy_depth = 1, _hierarchy_lineage="/#dummyPages[1]._hierarchy_id#/", _hierarchy_child_selector="/#dummyPages[1]._hierarchy_id#/#page._hierarchy_id#/%", _hierarchy_sort_order="/1/6/" } );
			for( var i=1; i lte 5; i++ ) {
				ArrayAppend( expected, { sort_order=i, _hierarchy_slug="/home/new-slug/child-2-#i#/", _hierarchy_depth = 2, _hierarchy_lineage="/#dummyPages[1]._hierarchy_id#/#page._hierarchy_id#/", _hierarchy_child_selector="/#dummyPages[1]._hierarchy_id#/#page._hierarchy_id#/#page.children[i]._hierarchy_id#/%", _hierarchy_sort_order="/1/6/#i#/" } );

				for( var n=1; n lte 5; n++ ) {
					ArrayAppend( expected, { sort_order=n, _hierarchy_slug="/home/new-slug/child-2-#i#/child-2-#i#-#n#/", _hierarchy_depth = 3, _hierarchy_lineage="/#dummyPages[1]._hierarchy_id#/#page._hierarchy_id#/#page.children[i]._hierarchy_id#/", _hierarchy_child_selector="/#dummyPages[1]._hierarchy_id#/#page._hierarchy_id#/#page.children[i]._hierarchy_id#/#page.children[i].children[n]._hierarchy_id#/%", _hierarchy_sort_order="/1/6/#i#/#n#/" } );
				}
			}

			// RESTORE THE PAGE
			treeSvc.restorePage(
				  id      = page.id
				, parent_page = dummyPages[1].id
				, slug        = "new-slug"
				, active      = 1
			);
			// END RESTORE THE PAGE

			// TEST THE DATA
			recycledAfter = poService.selectData(
				  objectName   = "page"
				, selectFields = [ "Count(*) as nPages" ]
				, filter       = { trashed = 1 }
				, useCache     = false
			);

			restoredPages = poService.selectData(
				  objectName   = "page"
				, filter       = "trashed = '0' and ( id = :id or _hierarchy_lineage like :_hierarchy_lineage )"
				, filterParams = { id = page.id, _hierarchy_lineage = "/#dummyPages[1]._hierarchy_id#/#page._hierarchy_id#/%" }
				, useCache     = false
				, orderBy      = "_hierarchy_sort_order"
			);

			nRecordsRestored =  recycledBefore.nPages - recycledAfter.nPages;

			super.assertEquals( 31, nRecordsRestored, "Number of records restored not as expected" );

			for( var i=1; i lte ArrayLen( expected ); i++ ) {
				for( var field in expected[i] ) {
					super.assertEquals( expected[i][field], restoredPages[field][i], "#field# was not the same for row #i#. Expected [#expected[i][field]#] but received [#restoredPages[field][i]#]." );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="test13_editPage_shouldThrowAnInformativeError_whenTheParentPageIsEqualToItself_whichWouldCauseAnInfiniteHierarchalLoop" returntype="void">
		<cfscript>
			var errorThrown = false;
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var page        = dummyPages[1].children[2].children[1];

			try {
				treeSvc.editPage( id = page.id, parent_page = page.id );
			} catch ( "SiteTreeService.BadParent" e ) {
				super.assertEquals( "A page in the site tree can not be set as the parent of itself", e.message );
				super.assertEquals( "Page with id, [#page.id#], was trying to set its parent page to itself", e.detail );

				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test14_editPage_shouldThrowAnInformativeError_whenTheParentPageIsBeneathItselfInTheTree_whichWouldCauseAnInfiniteHierarchalLoop" returntype="void">
		<cfscript>
			var errorThrown = false;
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var page        = dummyPages[1].children[5];

			try {
				treeSvc.editPage( id = page.id, parent_page = page.children[2].children[4].id );
			} catch ( "SiteTreeService.BadParent" e ) {
				super.assertEquals( "A page in the site tree can not be the parent of one of its ancestors", e.message );
				super.assertEquals( "Page with id, [#page.id#], was trying to set its parent page one of its descendants, [#page.children[2].children[4].id#]", e.detail );

				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test15_getTree_shouldReturnTheEntireSiteTreeInLogicalHierarchicalOrder" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var pages       = treeSvc.getTree( useCache=false );
			var expected    = dummyPages[1].id;

			for( var i=1; i lte 5; i++ ){
				expected = ListAppend( expected, dummyPages[1].children[i].id );

				for( var n=1; n lte 5; n++ ){
					expected = ListAppend( expected, dummyPages[1].children[i].children[n].id );

					for( var x=1; x lte 5; x++ ){
						expected = ListAppend( expected, dummyPages[1].children[i].children[n].children[x].id );
					}
				}
			}

			super.assertEquals( expected, ValueList( pages.id ) );
		</cfscript>
	</cffunction>

	<cffunction name="test16_getTree_shouldReturnTheTrashedTreeInOrder_whenTrashSpecified" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var pages       = "";
			var expected    = "";

			expected = ListAppend( expected, dummyPages[1].children[4].children[3].id );
			for( var i=1; i lte 5; i++ ){
				expected = ListAppend( expected, dummyPages[1].children[4].children[3].children[i].id );
			}

			expected = ListAppend( expected, dummyPages[1].children[2].id );
			for( var i=1; i lte 5; i++ ){
				expected = ListAppend( expected, dummyPages[1].children[2].children[i].id );

				for( var n=1; n lte 5; n++ ){
					expected = ListAppend( expected, dummyPages[1].children[2].children[i].children[n].id );
				}
			}

			treeSvc.trashPage( dummyPages[1].children[4].children[3].id );
			treeSvc.trashPage( dummyPages[1].children[2].id );
			treeSvc.editPage( id = dummyPages[1].children[4].children[3].id, sort_order = 0 ); // a little cheat to put it before some live pages

			pages = treeSvc.getTree( trash = true, useCache = false );

			super.assertEquals( expected, ValueList( pages.id ) );
		</cfscript>
	</cffunction>

	<cffunction name="test17_getTree_shouldNotReturnTrashedPages_whenTrashNotSpecifiedOrSetToFalse" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var pages       = "";
			var expected    = dummyPages[1].id;

			for( var i=1; i lte 5; i++ ){
				if ( i neq 2 ) {
					expected = ListAppend( expected, dummyPages[1].children[i].id );

					for( var n=1; n lte 5; n++ ){
						if ( not ( i eq 4 and n eq 3 ) ) {
							expected = ListAppend( expected, dummyPages[1].children[i].children[n].id );

							for( var x=1; x lte 5; x++ ){
								expected = ListAppend( expected, dummyPages[1].children[i].children[n].children[x].id );
							}
						}
					}
				}
			}

			treeSvc.trashPage( dummyPages[1].children[4].children[3].id );
			treeSvc.trashPage( dummyPages[1].children[2].id );
			treeSvc.editPage( id = dummyPages[1].children[4].children[3].id, sort_order = 0 ); // a little cheat to put it before some live pages

			pages = treeSvc.getTree( trash = false, useCache = false );

			super.assertEquals( expected, ValueList( pages.id ) );
		</cfscript>
	</cffunction>

	<cffunction name="test18_getPage_shouldReturnSpecifiedPage" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var page        = dummyPages[1].children[3].children[4].children[1];
			var pages       = treeSvc.getPage( id = page.id );

			super.assertEquals( page.id, ValueList( pages.id ) );
		</cfscript>
	</cffunction>

	<cffunction name="test19_getPage_shouldReturnEmptyQuery_whenPageNotFound" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var pages       = treeSvc.getPage( id = -234234 );

			super.assertFalse( pages.recordCount, "A page was returned even though none should be matched" );
		</cfscript>
	</cffunction>

	<cffunction name="test20_getTree_shouldOnlyReturnTheSpecifiedFields" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();

			pages = treeSvc.getTree( selectFields = [ "active", "page_type" ] );

			super.assertEquals( "active,page_type", pages.columnList );
		</cfscript>
	</cffunction>

	<cffunction name="test22_getPage_shouldReturnEmptyQuery_whenPageIsInTrash" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var page        = dummyPages[1].children[1];
			var pages       = "";

			treeSvc.trashPage( id = page.id );

			pages = treeSvc.getPage( id = page.id );

			super.assertFalse( pages.recordCount, "Page was returned, even though it was in the trash" );
		</cfscript>
	</cffunction>

	<cffunction name="test24_getPage_shouldReturnPage_whenPageIsInTrash_andIncludeTrashIsSetToTrue" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var page        = dummyPages[1].children[4];
			var pages       = "";

			treeSvc.trashPage( id = page.id );

			pages = treeSvc.getPage( id = page.id, includeTrash=true );

			super.assertEquals( page.id, ValueList( pages.id ), "Page was not returned" );
		</cfscript>
	</cffunction>

	<cffunction name="test25_getPage_shouldOnlyReturnSpecifiedFields" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var page        = dummyPages[1].children[4].children[5];
			var pages       = treeSvc.getPage( id = page.id, selectFields=[ "slug" ] );

			super.assertEquals( "slug", pages.columnList );
		</cfscript>
	</cffunction>

	<cffunction name="test26_getDescendants_shouldGetAllDescendantsOfGivenPage" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var pages       = treeSvc.getDescendants( dummyPages[1].id );
			var expected    = "";

			for( var i=1; i lte 5; i++ ){
				expected = ListAppend( expected, dummyPages[1].children[i].id );

				for( var n=1; n lte 5; n++ ){
					expected = ListAppend( expected, dummyPages[1].children[i].children[n].id );

					for( var x=1; x lte 5; x++ ){
						expected = ListAppend( expected, dummyPages[1].children[i].children[n].children[x].id );
					}
				}
			}

			super.assertEquals( expected, ValueList( pages.id ) );
		</cfscript>
	</cffunction>

	<cffunction name="test27_getDescendants_shouldOnlyGetDescendantsWithinAGivenDepth_whenADepthIsPassed" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var pages       = treeSvc.getDescendants( id = dummyPages[1].id, depth = 2 );
			var expected    = "";

			for( var i=1; i lte 5; i++ ){
				expected = ListAppend( expected, dummyPages[1].children[i].id );

				for( var n=1; n lte 5; n++ ){
					expected = ListAppend( expected, dummyPages[1].children[i].children[n].id );
				}
			}

			super.assertEquals( expected, ValueList( pages.id ) );
		</cfscript>
	</cffunction>

	<cffunction name="test28_getDescendants_shouldOnlyReturnSpecifiedFields" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var pages       = treeSvc.getDescendants(
				  id       = dummyPages[1].children[4].id
				, depth        = 2
				, selectFields = [ "Max( datecreated ) as lastCreatedDate" ]
			);

			super.assertEquals( "lastCreatedDate", pages.columnList );
		</cfscript>
	</cffunction>

	<cffunction name="test29_getAncestors_shouldGetAllAncestorsOfGivenPage" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var pages       = treeSvc.getAncestors( dummyPages[1].children[5].children[2].children[3].id );
			var expected    = "#dummyPages[1].id#,#dummyPages[1].children[5].id#,#dummyPages[1].children[5].children[2].id#";

			super.assertEquals( expected, ValueList( pages.id ) );
		</cfscript>
	</cffunction>

	<cffunction name="test30_getAncestors_shouldOnlyGetAncestorsWithinAGivenDepth_whenADepthIsPassed" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var pages       = treeSvc.getAncestors( id = dummyPages[1].children[5].children[2].children[3].id, depth=2 );
			var expected    = "#dummyPages[1].children[5].id#,#dummyPages[1].children[5].children[2].id#";

			super.assertEquals( expected, ValueList( pages.id ) );
		</cfscript>
	</cffunction>

	<cffunction name="test31_getAncestors_shouldOnlyReturnSpecifiedFields" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var pages       = treeSvc.getAncestors(
				  id       = dummyPages[1].children[4].id
				, selectFields = [ "Min( datecreated ) as oldest" ]
			);

			super.assertEquals( "oldest", pages.columnList );
		</cfscript>
	</cffunction>

	<cffunction name="test32_getAncestors_shouldIncludeSiblingsOfAncestorsAndSuppliedPage_whenIncludeSiblingsIsSetToTrue" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var pages       = treeSvc.getAncestors(
				  id          = dummyPages[1].children[5].children[2].children[3].id
				, depth           = 1
				, includeSiblings = true
			);

			var expected = dummyPages[1].children[5].children[1].id;

			expected = ListAppend( expected, dummyPages[1].children[5].children[2].id );

			for( i=1; i lte 5; i++ ) {
				expected = ListAppend( expected, dummyPages[1].children[5].children[2].children[i].id );
			}

			for( i=3; i lte 5; i++ ) {
				expected = ListAppend( expected, dummyPages[1].children[5].children[i].id );
			}

			super.assertEquals( expected, ValueList( pages.id ) );
		</cfscript>
	</cffunction>

	<cffunction name="test33_getPage_shouldReturnMatchingPageBySlug" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var page        = dummyPages[1].children[3].children[4].children[1];
			var pages       = treeSvc.getPage( slug="/home/child-3/child-3-4/child-3-4-1/" );

			super.assertEquals( page.id, ValueList( pages.id ) );
		</cfscript>
	</cffunction>

	<cffunction name="test35_getPage_shouldThrowInformativeError_whenNeitherSlugKeyNorObjIdIsPassed" returntype="void">
		<cfscript>
			var treeSvc = siteTreeService;
			var errorThrown = false;

			try {
				treeSvc.getPage();
			} catch ( "SiteTreeService.GetPage.MissingArgument" e ) {
				super.assertEquals( "Neither [id], [system_key] nor [slug] was passed to the getPage() method. You must specify one of either argument", e.message );
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test36_getTree_shouldReturnNestedArray_whenFormatEqualsNestedArray" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var pages       = treeSvc.getTree( format="nestedArray" );

			super.assert( IsArray( pages ) );

			super.assertEquals( dummyPages[1].id, pages[1].id );
			for( var i=1; i lte 5; i++ ){
				super.assertEquals( dummyPages[1].children[i].id, pages[1].children[i].id );
				for( var n=1; n lte 5; n++ ){
					super.assertEquals( dummyPages[1].children[i].children[n].id, pages[1].children[i].children[n].id );

					for( var x=1; x lte 5; x++ ){
						super.assertEquals( dummyPages[1].children[i].children[n].children[x].id, pages[1].children[i].children[n].children[x].id );
					}
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="test37_emptyTrash_shouldPermanentlyDeleteAllTrashedPages" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var pages       = "";
			var expected    = "";

			treeSvc.trashPage( dummyPages[1].children[4].children[3].id );
			treeSvc.trashPage( dummyPages[1].children[2].id );
			treeSvc.editPage( id = dummyPages[1].children[4].children[3].id, sort_order = 0 ); // a little cheat to put it before some live pages

			pages = treeSvc.getTree( trash = true, useCache = false );
			super.assert( pages.recordCount );

			treeSvc.emptyTrash();

			pages = treeSvc.getTree( trash = true, useCache = false );
			super.assert( not pages.recordCount );

			// just make sure we didn't delete all the non-trashed pages too!
			pages = treeSvc.getTree( trash = false, useCache = false);
			super.assert( pages.recordCount );
		</cfscript>
	</cffunction>

	<cffunction name="test38_getSiteHomepage_shouldReturnTheShallowistActivePageInTheTree" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var dummyPages  = _createADummySiteTreeWithAFewLevelsOfDepth();
			var page        = treeSvc.getSiteHomepage();
			var expected    = dummyPages[1].id;

			super.assert( page.recordCount );
			super.assertEquals( expected, page.id );
		</cfscript>
	</cffunction>

	<cffunction name="test39_getSiteHomepage_shouldCreateAHomepageIfNoneFound" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var page        = treeSvc.getSiteHomepage();

			super.assert( page.recordCount );
			super.assert( page.active );
			super.assertEquals( "Home"    , page.title );
			super.assertEquals( "homepage", page.page_type );
			super.assertEquals( ""        , page.slug );
			super.assertEquals( dummySite , page.site );
		</cfscript>
	</cffunction>

	<cffunction name="test40_addPage_shouldThrowInformativeError_whenNoParentSuppliedAndWhenAHomepageAlreadyExists" returntype="void">
		<cfscript>
			var treeSvc = siteTreeService;
			var page    = treeSvc.getSiteHomepage();
			var errorThrown = false;

			try {
				treeSvc.addPage(
					  title     = "testdatahere"
					, slug      = "testdatahere"
					, page_type = "standard_page"
				);

			} catch( "SiteTreeService.MissingParent" e ) {
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );

		</cfscript>
	</cffunction>

	<cffunction name="test41_editPage_shouldThrowAnInformativeError_whenEmptyParentSuppliedAndPageIsNotHomepage" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var parentpage  = treeSvc.getSiteHomepage();
			var errorThrown = false;

			var page = treeSvc.addPage(
				  title       = "testdatahere"
				, slug        = "testdatahere"
				, page_type   = "standard_page"
				, parent_page = parentpage.id
			);

			try {
				treeSvc.editPage( id=page, parent_page = "" );
			} catch( "SiteTreeService.MissingParent" e ) {
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test42_editPage_shouldThrowError_whenAttemptingToSetAParentOnTheHomepage" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var parentpage  = treeSvc.getSiteHomepage();
			var errorThrown = false;

			try {
				treeSvc.editPage( id=parentpage.id, parent_page = "something" );
			} catch( "SiteTreeService.BadHomepageOperation" e  ) {
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test43_editPage_shouldThrowError_whenAttemptingToTrashTheHomepage" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var parentpage  = treeSvc.getSiteHomepage();
			var errorThrown = false;

			try {
				treeSvc.editPage( id=parentpage.id, trashed = true );
			} catch( "SiteTreeService.BadHomepageOperation" e  ) {
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test44_editPage_shouldThrowError_whenAttemptingToDeactivateTheHomepage" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var parentpage  = treeSvc.getSiteHomepage();
			var errorThrown = false;

			try {
				treeSvc.editPage( id=parentpage.id, active = false );
			} catch( "SiteTreeService.BadHomepageOperation" e  ) {
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test45_permanentlyDeletePage_shouldThrowAnInformativeError_whenAttemptingToDeleteTheHomepage" returntype="void">
		<cfscript>
			var treeSvc     = siteTreeService;
			var parentpage  = treeSvc.getSiteHomepage();
			var errorThrown = false;

			try {
				treeSvc.permanentlyDeletePage( id=parentpage.id );
			} catch( "SiteTreeService.BadHomepageOperation" e  ) {
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

<!--- private --->
	<cffunction name="_wipeData" access="private" returntype="void" output="false">
		<cfscript>
			_deleteData( objectName="standard_page", forceDeleteAll=true );
			_deleteData( objectName="page"         , forceDeleteAll=true );
			_deleteData( objectName="security_user", forceDeleteAll=true );
			_deleteData( objectName="site"         , forceDeleteAll=true );
		</cfscript>
	</cffunction>

	<cffunction name="_setupDummyTreeData" access="private" returntype="void" output="false">
		<cfscript>
			variables.dummyUser = poService.insertData(
				  objectName="security_user"
				, data={ known_as="dummy", login_id="dummy", email_address="dummy", password=_bCryptPassword( "dummy" ) }
			);
			variables.dummySite = poService.insertData(
				  objectName="site"
				, data={ name="dummy", path="/", domain="127.0.0.1", protocol="http" }
			);

			mockColdboxEvent.$( "getSite", { id=dummySite } );
		</cfscript>
	</cffunction>

	<cffunction name="_login" access="private" returntype="void" output="false">
		<cfscript>
			loginService.login( loginId="dummy", password="dummy" );
		</cfscript>
	</cffunction>

	<cffunction name="_createADummySiteTreeWithAFewLevelsOfDepth" access="private" returntype="array" output="false">
		<cfargument name="inRecycleBin"        type="boolean" required="false" default="false" />
		<cfargument name="includeHierarchyIds" type="boolean" required="false" default="false" />
		<cfscript>
			var treeSvc = siteTreeService;
			var pages = [];
			var id    = 0;

			pages[1] = {
				  id       = treeSvc.addPage( title="Home", slug="home", page_type="homepage", active=true, trashed=arguments.inRecycleBin )
				, children = []
			};
			if ( includeHierarchyIds ) {
				pages[1]._hierarchy_id = _getHierarchyIdForPage( pages[1].id, treeSvc );
			}

			for( var i=1; i lte 5; i++ ) {
				pages[1].children[i] = {
					  id = treeSvc.addPage( parent_page=pages[1].id, title="Child #i#", slug="child-#i#", page_type="standard_page", active=true, trashed=arguments.inRecycleBin )
					, children = []
				}
				if ( includeHierarchyIds ) {
					pages[1].children[i]._hierarchy_id = _getHierarchyIdForPage( pages[1].children[i].id, treeSvc );
				}

				for( var n=1; n lte 5; n++ ) {
					pages[1].children[i].children[n] = {
						  id = treeSvc.addPage( parent_page=pages[1].children[i].id, title="Child #i#-#n#", slug="child-#i#-#n#", page_type="standard_page", active=true, trashed=arguments.inRecycleBin )
						, children = []
					}
					if ( includeHierarchyIds ) {
						pages[1].children[i].children[n]._hierarchy_id = _getHierarchyIdForPage( pages[1].children[i].children[n].id, treeSvc );
					}

					for( var x=1; x lte 5; x++ ) {
						pages[1].children[i].children[n].children[x] = {
							  id = treeSvc.addPage( parent_page=pages[1].children[i].children[n].id, title="Child #i#-#n#-#x#", slug="child-#i#-#n#-#x#", page_type="standard_page", active=true, trashed=arguments.inRecycleBin )
							, children = []
						}
						if ( includeHierarchyIds ) {
							pages[1].children[i].children[n].children[x]._hierarchy_id = _getHierarchyIdForPage( pages[1].children[i].children[n].children[x].id, treeSvc );
						}
					}
				}
			}

			return pages;
		</cfscript>
	</cffunction>

	<cffunction name="_getHierarchyIdForPage" access="private" returntype="numeric" output="false">
		<cfargument name="pageId" type="string" required="true" />
		<cfargument name="treeSvc" type="any" required="true" />

		<cfscript>
			var page = treeSvc.getPage(
				  id              = pageId
				, includeTrash    = true
				, selectFields    = [ "_hierarchy_id" ]
			);

			return Val( page._hierarchy_id );
		</cfscript>
	</cffunction>
--->
</cfcomponent>