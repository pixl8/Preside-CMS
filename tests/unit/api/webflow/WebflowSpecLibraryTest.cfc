component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "Webflow spec library", function() {

			beforeEach( function(){
				_webflowValidator = new cfflow.models.util.JsonSchemaValidator();
				_stepValidator = new cfflow.models.util.JsonSchemaValidator();
				_subflowValidator = new cfflow.models.util.JsonSchemaValidator();
				_yamlParser = new cfflow.models.util.YamlParser();
				_specLib = CreateMock( object=new preside.system.services.webflow.spec.WebflowSpecLibrary(
					  webflowValidator = _webflowValidator
					, stepValidator    = _stepValidator
					, subflowValidator = _subflowValidator
					, yamlParser       = _yamlParser
				) );

				_specLib.$( "$isFeatureEnabled", true );
			} );

			describe( "registerWebflow()", function(){
				it( "should register a valid yaml spec", function(){
					var yamlFilePath = ExpandPath( "/resources/webflow/valid.webflow.yml" );

					_specLib.$( "getStep", new preside.system.services.webflow.spec.WebflowStep() );
					_specLib.registerWebflow( yamlFilePath );
					expect( _specLib.getWebflow( "my.test.webflow" ).getId() ).toBe( "my.test.webflow" );
				} );
				it( "should register a valid struct", function(){
					var yamlFilePath  = ExpandPath( "/resources/webflow/valid.webflow.yml" );
					var webflowStruct = _yamlParser.deserialize( FileRead( yamlFilePath ) );

					_specLib.$( "getStep", new preside.system.services.webflow.spec.WebflowStep() );
					_specLib.registerWebflow( webflowStruct );
					expect( _specLib.getWebflow( "my.test.webflow" ).getId() ).toBe( "my.test.webflow" );
				} );
				it( "should set cfflowid by prefixing the given id", function(){
					var yamlFilePath = ExpandPath( "/resources/webflow/valid.webflow.yml" );

					_specLib.$( "getStep", new preside.system.services.webflow.spec.WebflowStep() );
					_specLib.registerWebflow( yamlFilePath );

					expect( _specLib.getWebflow( "my.test.webflow" ).getCfFlowId() ).toBe( "preside.webflow.my.test.webflow" );
				} );
				it( "should raise an error for grossly invalid specs", function(){
					var webflowStruct = { unacceptable=true };

					expect( function(){
						_specLib.registerWebflow( webflowStruct );
					} ).toThrow( "preside.webflow.invalid.spec" );
				} );
				it( "should ignore the webflow if it is marked with a feature that is not enabled", function(){
					var yamlFilePath = ExpandPath( "/resources/webflow/valid.webflow.yml" );

					_specLib.$( "getStep", new preside.system.services.webflow.spec.WebflowStep() );
					_specLib.$( "$isFeatureEnabled" ).$args( "somefeature" ).$results( false );
					_specLib.registerWebflow( yamlFilePath );
					expect( function(){
						_specLib.getWebflow( "my.test.webflow" );
					}).toThrow( "preside.webflow.not.found" );
				} );

			} );

			describe( "registerStep()", function(){
				it( "should register a valid yaml spec", function(){
					var yamlFilePath = ExpandPath( "/resources/webflow/valid.webflow.step.yml" );

					_specLib.registerStep( yamlFilePath );
					expect( _specLib.getStep( "choose-package" ).getId() ).toBe( "choose-package" );
				} );
				it( "should register a valid struct", function(){
					var yamlFilePath  = ExpandPath( "/resources/webflow/valid.webflow.step.yml" );
					var webflowStruct = _yamlParser.deserialize( FileRead( yamlFilePath ) );

					_specLib.registerStep( webflowStruct );
					expect( _specLib.getStep( "choose-package" ).getId() ).toBe( "choose-package" );
				} );
				it( "should raise an error for grossly invalid specs", function(){
					var webflowStruct = { unacceptable=true };

					expect( function(){
						_specLib.registerStep( webflowStruct );
					} ).toThrow( "preside.webflow.step.invalid.spec" );
				} );
				it( "should ignore the spec if belongs to a feature that is not enabled", function(){
					var yamlFilePath = ExpandPath( "/resources/webflow/valid.webflow.step.yml" );

					_specLib.$( "$isFeatureEnabled" ).$args( "somefeature" ).$results( false );
					_specLib.registerStep( yamlFilePath );

					expect( function(){
						_specLib.getStep( "choose-package" );
					} ).toThrow( "preside.webflow.step.not.found" );
				} );
			} );

			describe( "registerSubFlow", function() {
				it( "should register a valid yaml spec", function(){
					var yamlFilePath = ExpandPath( "/resources/webflow/subflows/valid.subflow.yml" );

					_specLib.registerSubflow( yamlFilePath );
					expect( _specLib.getSubflow( "login-register" ).getId() ).toBe( "login-register" );
				} );
				it( "should register a valid struct", function(){
					var yamlFilePath = ExpandPath( "/resources/webflow/subflows/valid.subflow.yml" );
					var subflowStruct = _yamlParser.deserialize( FileRead( yamlFilePath ) );

					_specLib.registerSubflow( subflowStruct );
					expect( _specLib.getSubflow( "login-register" ).getId() ).toBe( "login-register" );
				} );
				it( "should raise an error for grossly invalid specs", function(){
					var subflowStruct = { unacceptable=true };

					expect( function(){
						_specLib.registerSubflow( subflowStruct );
					} ).toThrow( "preside.webflow.subflow.invalid.spec" );
				} );
				it( "should ignore specs that belong to a feature that is not enabled", function(){
					var yamlFilePath = ExpandPath( "/resources/webflow/subflows/valid.subflow.yml" );

					_specLib.$( "$isFeatureEnabled" ).$args( "somefeature" ).$results( false );
					_specLib.registerSubflow( yamlFilePath );

					expect( function(){
						_specLib.getSubflow( "login-register" );
					} ).toThrow( "preside.webflow.subflow.not.found" );
				} );
			} );
		} );
	}

}