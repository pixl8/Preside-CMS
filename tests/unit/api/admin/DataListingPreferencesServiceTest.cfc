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
		var mockDataManager    = createStub();
		var mockCustomization  = createStub();
		var mockEnum           = createStub();

		mockCustomization.$( "runCustomization", "" );

		return CreateMock( object=new preside.system.services.admin.DataListingPreferencesService(
			  dataManagerService       = mockDataManager
			, customizationService     = mockCustomization
			, enumService              = mockEnum
			, rulesEngineFilterService = NullValue()
		) );
	}

}
