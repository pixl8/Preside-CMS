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

		describe( "getExpressionFieldsFromFunctionDefinition()", function(){
			it( "should return struct containing keys that are the names of non-core-expected arguments to the function", function(){
				var service = _getService();
				var dummyFunction = {
					parameters = [
						  { name="test" }
						, { name="event" }
						, { name="rc" }
						, { name="prc" }
						, { name="stuff" }
						, { name="args" }
						, { name="payload" }
						, { name="context" }
						, { name="_is" }
						, { name="_any" }
					]
				};

				service.$( "getFieldDefinition", {} );

				var fields = service.getExpressionFieldsFromFunctionDefinition( dummyFunction );
				expect( fields.keyArray().sort( "textnocase" ) ).toBe( [ "_any", "_is", "stuff", "test" ] );
			} );

			it( "should return configuration for each found field using the getFieldDefinition() method", function(){
				var service = _getService();
				var dummyFunction = {
					parameters = [
						  { name="test" }
						, { name="event" }
						, { name="rc" }
						, { name="prc" }
						, { name="stuff" }
						, { name="args" }
						, { name="payload" }
						, { name="context" }
						, { name="_is" }
						, { name="_any" }
					]
				};
				var definitions = {
					  test  = { test=CreateUUId() }
					, stuff = { test=CreateUUId() }
					, _is   = { test=CreateUUId() }
					, _any  = { test=CreateUUId() }
				};

				service.$( "getFieldDefinition" ).$args( dummyFunction.parameters[1 ] ).$results( definitions.test  );
				service.$( "getFieldDefinition" ).$args( dummyFunction.parameters[5 ] ).$results( definitions.stuff );
				service.$( "getFieldDefinition" ).$args( dummyFunction.parameters[9 ] ).$results( definitions._is   );
				service.$( "getFieldDefinition" ).$args( dummyFunction.parameters[10] ).$results( definitions._any  );

				var fields = service.getExpressionFieldsFromFunctionDefinition( dummyFunction );
				expect( fields ).toBe( definitions );
			} );
		} );

		describe( "getFieldDefinition()", function(){
			it( "should return 'boolean' type and 'isIsNot' variety when argument name = '_is'", function(){
				var service    = _getService();
				var argument   = { name="_is" };
				var definition = service.getFieldDefinition( argument );

				expect( definition ).toBe( { fieldType="boolean", variety="isIsNot" } );
			} );

			it( "should return 'boolean' type and 'hasHasNot' variety when argument name = '_has'", function(){
				var service    = _getService();
				var argument   = { name="_has" };
				var definition = service.getFieldDefinition( argument );

				expect( definition ).toBe( { fieldType="boolean", variety="hasHasNot" } );
			} );

			it( "should return 'boolean' type and 'wasWasNot' variety when argument name = '_was'", function(){
				var service    = _getService();
				var argument   = { name="_was" };
				var definition = service.getFieldDefinition( argument );

				expect( definition ).toBe( { fieldType="boolean", variety="wasWasNot" } );
			} );

			it( "should return 'boolean' type and 'willWillNot' variety when argument name = '_will'", function(){
				var service    = _getService();
				var argument   = { name="_will" };
				var definition = service.getFieldDefinition( argument );

				expect( definition ).toBe( { fieldType="boolean", variety="willWillNot" } );
			} );

			it( "should return 'scope' type when argument name = '_all'", function(){
				var service    = _getService();
				var argument   = { name="_all" };
				var definition = service.getFieldDefinition( argument );

				expect( definition ).toBe( { fieldType="scope" } );
			} );

			it( "should return 'scope' type when argument name = '_any'", function(){
				var service    = _getService();
				var argument   = { name="_any" };
				var definition = service.getFieldDefinition( argument );

				expect( definition ).toBe( { fieldType="scope" } );
			} );

			it( "should merge argument metadata that is not 'name', 'type' or 'hint' into the field definition", function(){
				var service    = _getService();
				var argument   = { name="_any", type="boolean", hint="Any/all", test="this", stuff=true, required=true };
				var definition = service.getFieldDefinition( argument );

				expect( definition ).toBe( { fieldType="scope", test="this", stuff=true, required=true } );
			} );

			it( "should derive the 'fieldType' of the argument from the argument type when no 'fieldType' meta is set for the argument", function(){
				var service    = _getService();
				var argument   = { name="someArg", type="numeric", required=true };
				var derivedType = CreateUUId();

				service.$( "getDefaultFieldTypeForArgumentType" ).$args( argument.type ).$results( derivedType );

				var definition = service.getFieldDefinition( argument );

				expect( definition ).toBe( { fieldType=derivedType, required=true } );
			} );

		} );
	}


// PRIVATE HELPERS
	private any function _getService() {
		var service = new preside.system.services.rulesEngine.RulesEngineExpressionReaderService();

		return createMock( object=service );
	}

}