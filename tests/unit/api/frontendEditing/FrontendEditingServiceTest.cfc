component extends="tests.resources.HelperObjects.PresideBddTestCase" {


	function run(){

		describe( "saveContent()", function(){
			it( "should refuse to save when the object is not a page or page type", function(){
				var service    = _getService();
				var objectName = "someObject";
				var recordId   = CreateUUId();
				var propName   = "someProperty";
				var content    = CreateUUId();

				mockPresideObjectService.$( "updateData", 1 );
				mockSiteTreeService.$( "editPage", 1 );

				expect( service.saveContent(
					  object   = objectName
					, property = propName
					, recordId = recordId
					, content  = content
				) ).toBeFalse();

				expect( mockPresideObjectService.$callLog().updateData.len() ).toBe( 0 );
				expect( mockSiteTreeService.$callLog().editPage.len() ).toBe( 0 );
			} );

			it( "should use sitetree service to save draft when object is 'page'", function(){
				var service    = _getService();
				var objectName = "page";
				var recordId   = CreateUUId();
				var propName   = "title";
				var content    = CreateUUId();

				mockSiteTreeService.$( "editPage", 1 );

				expect( service.saveContent(
					  object   = objectName
					, property = propName
					, recordId = recordId
					, content  = content
				) ).toBeTrue();

				var log = mockSiteTreeService.$callLog().editPage;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  id      = recordId
					, isDraft = true
					, title   = content
				} );

			} );

			it( "should use sitetree service to save draft when object is a page type", function(){
				var service    = _getService();
				var objectName = "homepage";
				var recordId   = CreateUUId();
				var propName   = "title";
				var content    = CreateUUId();

				mockPresideObjectService.$( "objectExists" ).$args( objectName ).$results( true );
				mockPresideObjectService.$( "isPageType" ).$args( objectName ).$results( true );
				mockSiteTreeService.$( "editPage", 1 );

				expect( service.saveContent(
					  object   = objectName
					, property = propName
					, recordId = recordId
					, content  = content
				) ).toBeTrue();

				var log = mockSiteTreeService.$callLog().editPage;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  id      = recordId
					, isDraft = true
					, title   = content
				} );

			} );
		} );


	}

// PRIVATE HELPERS
	private any function _getService() {
		mockSiteTreeService      = CreateEmptyMock( "preside.system.services.siteTree.SiteTreeService" );
		mockPresideObjectService = CreateEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );

		var service = CreateMock( object=new preside.system.services.frontendEditing.FrontendEditingService( sitetreeService=mockSiteTreeService ) );
		service.$( "$getPresideObjectService", mockPresideObjectService );
		service.$( "$audit" );

		mockPresideObjectService.$( "objectExists", false );
		mockPresideObjectService.$( "isPageType", false );

		return service;
	}

}