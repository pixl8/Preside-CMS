component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "getExpressionsFromCfc()", function(){
			it( "should return a struct of expression IDs relative to the base folder. Where expression id is made up of CFC name + handler action and where only handler actions tagged as '@expression' are included", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";

				service.$( "getExpressionFieldsFromFunctionDefinition", {} );

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions.keyArray().sort( "textnocase" ) ).toBe( [ "SimpleExpressionHandler.global", "SimpleExpressionHandler.user" ] );
			} );

			it( "should detail the contexts of each expression as configured by the @expressionContexts tag on the function", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";

				service.$( "getExpressionFieldsFromFunctionDefinition", {} );

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions[ "SimpleExpressionHandler.user" ].contexts ?: "" ).toBe( [ "user", "marketing" ] );
			} );

			it( "should set a default context using the function name when the expression handler function does not set an @expressionContexts", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";

				service.$( "getExpressionFieldsFromFunctionDefinition", {} );

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions[ "SimpleExpressionHandler.global" ].contexts ?: "" ).toBe( [ "global" ] );
			} );

			it( "should set field definitions for each expression based on the function metadata", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";
				var meta     = GetComponentMetadata( cfc );
				var dummyDefs = { test=CreateUUId() };

				service.$( "getExpressionFieldsFromFunctionDefinition" ).$args( meta.functions[1] ).$results( dummyDefs );
				service.$( "getExpressionFieldsFromFunctionDefinition" ).$args( meta.functions[2] ).$results( {} );

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions[ "SimpleExpressionHandler.user" ].fields ?: "" ).toBe( dummyDefs );
			} );
		} );

	}


// PRIVATE HELPERS
	private any function _getService() {
		var service = new preside.system.services.rulesEngine.RulesEngineExpressionReaderService();

		return createMock( object=service );
	}

}