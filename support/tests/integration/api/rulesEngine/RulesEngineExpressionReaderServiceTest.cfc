component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "getExpressionsFromCfc()", function(){
			it( "should return a struct of expression IDs relative to the base folder. Where expression id is made up of CFC name + handler action and where only handler actions tagged as '@expression' are included", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions.keyArray().sort( "textnocase" ) ).toBe( [ "SimpleExpressionHandler.event_booking", "SimpleExpressionHandler.user" ] );
			} );
		} );


	}


// PRIVATE HELPERS
	private any function _getService() {
		return new preside.system.services.rulesEngine.RulesEngineExpressionReaderService();
	}

}