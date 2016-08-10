component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

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
		var service = new preside.system.services.rulesEngine.RulesEngineFieldTypeServiceTest();

		service = createMock( object=service );

		return service;
	}

}