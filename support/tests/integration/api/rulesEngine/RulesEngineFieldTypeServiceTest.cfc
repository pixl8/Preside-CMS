component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "getHandlerForFieldType()", function(){
			it( "should use convention to return name of handler to use for field type actions", function(){
				var service = _getService();

				expect( service.getHandlerForFieldType( "myfieldtype" ) ).toBe( "rules.fieldtypes.myfieldtype" );
			} );
		} );

		describe( "renderConfiguredField()", function(){
			it( "should do things", function(){
				fail( "but we haven't yet implemented anything" );
			} );
		} );

		describe( "renderConfigurationScreen()", function(){
			it( "should do things", function(){
				fail( "but we haven't yet implemented anything" );
			} );
		} );

		describe( "processConfigurationScreenSubmission()", function(){
			it( "should do things", function(){
				fail( "but we haven't yet implemented anything" );
			} );
		} );

		describe( "prepareConfiguredFieldData()", function(){
			it( "should do things", function(){
				fail( "but we haven't yet implemented anything" );
			} );
		} );

	}

// PRIVATE HELPERS
	private any function _getService() {
		var service = new preside.system.services.rulesEngine.RulesEngineFieldTypeService();

		service = createMock( object=service );

		return service;
	}

}