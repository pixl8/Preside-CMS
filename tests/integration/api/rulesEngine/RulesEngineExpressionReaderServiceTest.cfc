component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "getExpressionsFromCfc()", function(){
			it( "should return a struct of expression IDs relative to the base folder. Where expression id is based on CFC name", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";

				service.$( "getExpressionFieldsFromFunctionDefinition", {} );

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions.keyArray().sort( "textnocase" ) ).toBe( [ "SimpleExpressionHandler" ] );
			} );

			it( "should detail the expanded contexts as configured by the @expressionContexts tag on the CFC", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";
				var expandedContexts = [ "test", "another", "context", CreateUUId() ];

				service.$( "getExpressionFieldsFromFunctionDefinition", {} );
				mockContextService.$( "expandContexts" ).$args( [ "user", "marketing" ] ).$results( expandedContexts );

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions[ "SimpleExpressionHandler" ].contexts ?: "" ).toBe( expandedContexts );
			} );

			it( "should set expand a default 'global' context when the expression CFC does not set an @expressionContexts attribute", function(){
				var service          = _getService();
				var cfc              = "resources.rulesEngine.expressions.GlobalExpressionHandler";
				var rootPath         = "resources.rulesEngine.expressions";
				var expandedContexts = [ "test", "another", "context" ];

				service.$( "getExpressionFieldsFromFunctionDefinition", {} );
				mockContextService.$( "expandContexts" ).$args( [ "global" ] ).$results( expandedContexts );

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions[ "GlobalExpressionHandler" ].contexts ?: "" ).toBe( expandedContexts );
			} );

			it( "should set field definitions based on the 'evaluate' function metadata", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";
				var meta     = GetComponentMetadata( cfc );
				var dummyDefs = { test=CreateUUId() };

				service.$( "getExpressionFieldsFromFunctionDefinition" ).$args( meta.functions[1] ).$results( dummyDefs );

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions[ "SimpleExpressionHandler" ].fields ?: "" ).toBe( dummyDefs );
			} );

			it( "should return an empty struct when the CFC file is annotated with a disabled feature", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";
				var meta     = GetComponentMetadata( cfc );
				var dummyDefs = { test=CreateUUId() };

				service.$( "$isFeatureEnabled" ).$args( meta.feature ).$results( false );

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions.count() ).toBe( 0 );
			} );

			it( "should return an empty struct when the CFC file is annotated with context(s) that do not exist", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";
				var meta     = GetComponentMetadata( cfc );
				var dummyDefs = { test=CreateUUId() };

				mockContextService.$( "contextExists" ).$args( "user" ).$results( false );
				mockContextService.$( "contextExists" ).$args( "marketing" ).$results( false );

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions.count() ).toBe( 0 );
			} );

			it( "should set an array of filter objects based on the CFC file having a prepareFilters() method tagged with a @objects attribute", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";
				var meta     = GetComponentMetadata( cfc );
				var dummyDefs = { test=CreateUUId() };

				service.$( "getExpressionFieldsFromFunctionDefinition" ).$args( meta.functions[1] ).$results( dummyDefs );

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions[ "SimpleExpressionHandler" ].filterObjects ?: [] ).toBe( [ "object1", "object2" ] );
			} );

			it( "should set a category based on @expressionCategory attribute on the CFC", function(){
				var service  = _getService();
				var cfc      = "resources.rulesEngine.expressions.SimpleExpressionHandler";
				var rootPath = "resources.rulesEngine.expressions";
				var meta     = GetComponentMetadata( cfc );
				var dummyDefs = { test=CreateUUId() };

				service.$( "getExpressionFieldsFromFunctionDefinition" ).$args( meta.functions[1] ).$results( dummyDefs );

				var expressions = service.getExpressionsFromCfc( componentPath=cfc, rootPath=rootPath );

				expect( expressions[ "SimpleExpressionHandler" ].category ?: "" ).toBe( "testCategory" );
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

			it( "should return 'boolean' type and 'allAny' variety when argument name = '_all'", function(){
				var service    = _getService();
				var argument   = { name="_all" };
				var definition = service.getFieldDefinition( argument );

				expect( definition ).toBe( { fieldType="boolean", variety="allAny" } );
			} );

			it( "should return 'operator' type and 'string' variety when argument name = '_stringOperator'", function(){
				var service    = _getService();
				var argument   = { name="_stringOperator" };
				var definition = service.getFieldDefinition( argument );

				expect( definition ).toBe( { fieldType="operator", variety="string" } );
			} );

			it( "should return 'operator' type and 'date' variety when argument name = '_dateOperator'", function(){
				var service    = _getService();
				var argument   = { name="_dateOperator" };
				var definition = service.getFieldDefinition( argument );

				expect( definition ).toBe( { fieldType="operator", variety="date" } );
			} );

			it( "should return 'operator' type and 'numeric' variety when argument name = '_numericOperator'", function(){
				var service    = _getService();
				var argument   = { name="_numericOperator" };
				var definition = service.getFieldDefinition( argument );

				expect( definition ).toBe( { fieldType="operator", variety="numeric" } );
			} );

			it( "should merge argument metadata that is not 'name', 'type' or 'hint' into the field definition", function(){
				var service    = _getService();
				var argument   = { name="_any", type="boolean", hint="Any/all", test="this", stuff=true, required=true };
				var definition = service.getFieldDefinition( argument );

				expect( definition ).toBe( { fieldType="boolean", test="this", stuff=true, required=true } );
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

		describe( "getDefaultFieldTypeForArgumentType()", function(){
			it( "should return 'number' when argument type = 'numeric'", function(){
				var service = _getService();

				expect( service.getDefaultFieldTypeForArgumentType( "numeric" ) ).toBe( "number" );
			} );

			it( "should return 'text' when argument type = 'string'", function(){
				var service = _getService();

				expect( service.getDefaultFieldTypeForArgumentType( "string" ) ).toBe( "text" );
			} );

			it( "should return 'date' when argument type = 'date'", function(){
				var service = _getService();

				expect( service.getDefaultFieldTypeForArgumentType( "date" ) ).toBe( "date" );
			} );

			it( "should return 'boolean' when argument type = 'boolean'", function(){
				var service = _getService();

				expect( service.getDefaultFieldTypeForArgumentType( "boolean" ) ).toBe( "boolean" );
			} );

			it( "should return 'text' for any other type", function(){
				var service = _getService();

				expect( service.getDefaultFieldTypeForArgumentType( CreateUUId() ) ).toBe( "text" );
			} );
		} );

		describe( "getExpressionsFromDirectory()", function(){
			it( "should merge the results of getting expressions from every CFC file beneath the passed directory", function(){
				var service = _getService();
				var rootDir = "/resources/rulesEngine/expressions";
				var files   = [
					  { path="resources.rulesEngine.expressions.SimpleExpressionHandler"             , expressions={ test1=CreateUUId(), fubar={ test=CreateUUId() } } }
					, { path="resources.rulesEngine.expressions.GlobalExpressionHandler"             , expressions={ test5=CreateUUId() } }
					, { path="resources.rulesEngine.expressions.subfolder.AGreatHandler"             , expressions={ test2=CreateUUId() } }
					, { path="resources.rulesEngine.expressions.subfolder.AnotherHandler"            , expressions={ test3=CreateUUId() } }
					, { path="resources.rulesEngine.expressions.subfolder.subagain.ExpressionHandler", expressions={ test4=CreateUUId() } }
				];
				var expected = {};

				for( var file in files ) {
					service.$( "getExpressionsFromCfc" ).$args(
						  componentPath = file.path
						, rootPath      = "resources.rulesEngine.expressions"
					).$results( file.expressions );

					expected.append( file.expressions );
				}
				service.getExpressionsFromDirectory( rootDir );

				expect( service.getExpressionsFromDirectory( rootDir ) ).toBe( expected );
			} );
		} );

		describe( "getExpressionsFromDirectories()", function(){
			it( "should merge the results of getting expressions from each of the passed directories", function(){
				var service     = _getService();
				var expected    = {};
				var rawDirs     = [];
				var directories = [
					  { dir="/some/dir"                   , expressions={ test1=CreateUUId(), another1={ test=CreateUUId() } } }
					, { dir="/another/awesome/dir"        , expressions={ test2=CreateUUId(), another2={ test=CreateUUId() } } }
					, { dir="/yes/this/is/adir"           , expressions={ test3=CreateUUId(), another3={ test=CreateUUId() } } }
					, { dir="/something/without/dir/in/it", expressions={ test4=CreateUUId(), another4={ test=CreateUUId() } } }
					, { dir="/oops"                       , expressions={ test5=CreateUUId(), another5={ test=CreateUUId() } } }
				];

				for( var dir in directories ) {
					expected.append( dir.expressions );
					rawDirs.append( dir.dir );

					service.$( "getExpressionsFromDirectory" ).$args( dir.dir ).$results( dir.expressions );
				}

				expect( service.getExpressionsFromDirectories( rawDirs ) ).toBe( expected );
			} );
		} );
	}


// PRIVATE HELPERS
	private any function _getService() {
		mockContextService = createEmptyMock( "preside.system.services.rulesEngine.RulesEngineContextService" );
		var service = createMock( object=new preside.system.services.rulesEngine.RulesEngineExpressionReaderService(
			contextService = mockContextService
		) );

		service.$( "$isFeatureEnabled", true );

		mockContextService.$( "expandContexts", [ "global" ] );
		mockContextService.$( "contextExists", true );

		return service;
	}

}