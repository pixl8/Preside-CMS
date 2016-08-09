component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "getExpressionsFromCfc()", function(){
			it( "should return a struct of expression IDs relative to the base folder. Where expression id is made up of CFC name + handler action and where only handler actions tagged as '@expression' are included", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions.keyArray().sort( "textnocase" ) ).toBe( [ "SimpleExpressionHandler.global", "SimpleExpressionHandler.user" ] );
			} );

			it( "it should detail the contexts of each expression as configured by the @expressionContexts tag on the function", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions[ "SimpleExpressionHandler.user" ].contexts ?: "" ).toBe( [ "user", "marketing" ] );
			} );

			it( "it should set a default context using the function name when the expression handler function does not set an @expressionContexts", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions[ "SimpleExpressionHandler.global" ].contexts ?: "" ).toBe( [ "global" ] );
			} );
		} );

	}


// PRIVATE HELPERS
	private any function _getService() {
		var service = new preside.system.services.rulesEngine.RulesEngineExpressionReaderService();

		return createMock( object=service );
	}

}