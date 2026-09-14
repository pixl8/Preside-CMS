component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "applyUserColumns()", function(){
			it( "should keep locked fields first and drop fields that are not available", function(){
				var svc = _getService();

				svc.$( "listLockedColumns" ).$args( "crm_contact" ).$results( [ "label" ] );

				var result = svc.applyUserColumns(
					  objectName    = "crm_contact"
					, defaultFields = [ "label", "email" ]
					, available     = [ "label", "email", "datemodified" ]
					, storedFields  = [ "email", "hacked", "datemodified" ]
				);

				expect( result ).toBe( [ "label", "email", "datemodified" ] );
			} );

			it( "should use default fields when no stored preference exists", function(){
				var svc = _getService();

				svc.$( "listLockedColumns" ).$args( "crm_contact" ).$results( [ "label" ] );

				var result = svc.applyUserColumns(
					  objectName    = "crm_contact"
					, defaultFields = [ "label", "email" ]
					, available     = [ "label", "email", "phone" ]
					, storedFields  = []
				);

				expect( result ).toBe( [ "label", "email" ] );
			} );

			it( "should persist the supplied columns rather than the previously stored preference", function(){
				var svc = _getService();

				svc.$( "listLockedColumns" ).$args( "crm_contact" ).$results( [ "label" ] );

				var result = svc.applyUserColumns(
					  objectName    = "crm_contact"
					, defaultFields = [ "label", "email" ]
					, available     = [ "label", "email", "phone" ]
					, storedFields  = [ "label", "phone" ]
				);

				expect( result ).toBe( [ "label", "phone" ] );
			} );
		} );

		describe( "listAvailableColumns()", function(){
			it( "should merge explicitly passed columns with annotated grid fields", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				variables.mockDataManager.$( "listGridFields" ).$args( "email_template" ).$results( [ "name", "datecreated", "datemodified" ] );
				variables.mockDataManager.$( "listHiddenGridFields" ).$args( "email_template" ).$results( [] );
				variables.mockDataManager.$( "listSearchFields" ).$args( "email_template" ).$results( [] );
				mockPoService.$( "getObjectAttribute", "" );
				mockPoService.$( "getObjectProperties", {
					  name           = { name="name" }
					, datecreated    = { name="datecreated" }
					, datemodified   = { name="datemodified" }
					, sending_method = { name="sending_method" }
					, open_rate      = { name="open_rate" }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				var result = svc.listAvailableColumns(
					  objectName  = "email_template"
					, extraFields = [ "name", "sending_method", "open_rate" ]
				);

				expect( ArrayFindNoCase( result, "name" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "datecreated" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "sending_method" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "open_rate" ) ).toBeGT( 0 );
			} );

			it( "should expand wildcard picker fields and drop named exclusions", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				variables.mockDataManager.$( "listGridFields" ).$args( "my_extension_object" ).$results( [ "label", "status" ] );
				variables.mockDataManager.$( "listHiddenGridFields" ).$args( "my_extension_object" ).$results( [] );
				variables.mockDataManager.$( "listSearchFields" ).$args( "my_extension_object" ).$results( [] );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "my_extension_object"
					, attributeName = "datamanagerColumnPickerFields"
					, defaultValue  = ""
				).$results( "*,!sensitive_col,!other_sensitive_col" );
				mockPoService.$( "getObjectProperties", {
					  label               = { name="label" }
					, status              = { name="status" }
					, notes               = { name="notes" }
					, datemodified        = { name="datemodified" }
					, sensitive_col       = { name="sensitive_col" }
					, other_sensitive_col = { name="other_sensitive_col" }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				var result = svc.listAvailableColumns( objectName="my_extension_object" );

				expect( ArrayFindNoCase( result, "notes" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "datemodified" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "sensitive_col" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "other_sensitive_col" ) ).toBe( 0 );
			} );

			it( "should match glob exclusions in picker fields", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				variables.mockDataManager.$( "listGridFields" ).$args( "my_extension_object" ).$results( [ "label" ] );
				variables.mockDataManager.$( "listHiddenGridFields" ).$args( "my_extension_object" ).$results( [] );
				variables.mockDataManager.$( "listSearchFields" ).$args( "my_extension_object" ).$results( [] );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "my_extension_object"
					, attributeName = "datamanagerColumnPickerFields"
					, defaultValue  = ""
				).$results( "*,!*_col" );
				mockPoService.$( "getObjectProperties", {
					  label               = { name="label" }
					, notes               = { name="notes" }
					, sensitive_col       = { name="sensitive_col" }
					, other_sensitive_col = { name="other_sensitive_col" }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				var result = svc.listAvailableColumns( objectName="my_extension_object" );

				expect( ArrayFindNoCase( result, "notes" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "sensitive_col" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "other_sensitive_col" ) ).toBe( 0 );
			} );
		} );

		describe( "mergeExpressionArrays()", function(){
			it( "should AND two expression arrays together", function(){
				var svc    = _getService();
				var left   = [ { expression="a", fields={} } ];
				var right  = [ { expression="b", fields={} } ];
				var merged = svc.mergeExpressionArrays( left, right );

				expect( merged.len() ).toBe( 3 );
				expect( merged[ 2 ] ).toBe( "and" );
				expect( merged[ 1 ].expression ).toBe( "a" );
				expect( merged[ 3 ].expression ).toBe( "b" );
			} );

			it( "should return the non-empty side when the other is empty", function(){
				var svc = _getService();

				expect( svc.mergeExpressionArrays( [], [ { expression="b" } ] ) ).toBe( [ { expression="b" } ] );
				expect( svc.mergeExpressionArrays( [ { expression="a" } ], [] ) ).toBe( [ { expression="a" } ] );
			} );
		} );
	}

	private any function _getService() {
		variables.mockDataManager   = createStub();
		variables.mockCustomization = createStub();
		variables.mockEnum          = createStub();

		variables.mockCustomization.$( "runCustomization", "" );

		return CreateMock( object=new preside.system.services.admin.DataListingPreferencesService(
			  dataManagerService       = variables.mockDataManager
			, customizationService     = variables.mockCustomization
			, enumService              = variables.mockEnum
			, rulesEngineFilterService = NullValue()
		) );
	}

}
