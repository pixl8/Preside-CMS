component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "Custom fields tab", function(){
			beforeEach( function(){
				variables.handler = CreateMock( object=new preside.system.base.EnhancedDataManagerBase() );
				variables.customFieldsService = createStub();

				handler.$property( propertyName="presideCustomFieldsService", mock=customFieldsService );
				handler.$( "isFeatureEnabled", true );
				makePublic( handler, "_addCustomFieldsTab", "addCustomFieldsTab" );
				makePublic( handler, "_getCustomFieldsForRecord", "getCustomFieldsForRecord" );
			} );

			it( "should add the tab when the record has custom fields", function(){
				var args = {
					  objectName = "test_object"
					, record     = { id="record-1" }
					, tabs       = [ "default" ]
				};
				customFieldsService.$( "isObjectEnabled", true );
				customFieldsService.$( "listFieldsForRecord", [ { key="custom_one" } ] );

				handler.addCustomFieldsTab( event={}, rc={}, prc={}, args=args );

				expect( args.tabs ).toBe( [ "default", "customFields" ] );
			} );

			it( "should preserve an explicitly positioned custom fields tab", function(){
				var args = {
					  objectName = "test_object"
					, record     = { id="record-1" }
					, tabs       = [ "default", { id="more", children=[ "auditTrail", "customFields" ] } ]
				};
				customFieldsService.$( "isObjectEnabled", true );
				customFieldsService.$( "listFieldsForRecord", [ { key="custom_one" } ] );

				handler.addCustomFieldsTab( event={}, rc={}, prc={}, args=args );

				expect( args.tabs ).toBe( [ "default", { id="more", children=[ "auditTrail", "customFields" ] } ] );
			} );

			it( "should not add the tab when the record has no custom fields", function(){
				var args = {
					  objectName = "test_object"
					, record     = { id="record-1" }
					, tabs       = [ "default" ]
				};
				customFieldsService.$( "isObjectEnabled", true );
				customFieldsService.$( "listFieldsForRecord", [] );

				handler.addCustomFieldsTab( event={}, rc={}, prc={}, args=args );

				expect( args.tabs ).toBe( [ "default" ] );
			} );

			it( "should allow the automatic tab to be disabled", function(){
				var args = {
					  objectName = "test_object"
					, record     = { id="record-1" }
					, tabs       = [ "default" ]
				};
				handler.$property( propertyName="customFieldsTabEnabled", mock=false );

				handler.addCustomFieldsTab( event={}, rc={}, prc={}, args=args );

				expect( args.tabs ).toBe( [ "default" ] );
			} );
		} );
	}

}
