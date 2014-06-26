component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

	function test01_newRuleset_shouldReturnANewlyInstantiatedRulesetObject(){
		var engine = _getEngine();
		var ruleset = "";
		var filePath = ListAppend( GetTempDirectory(), CreateUUId() );
		var expected = [
			  { fieldName="another_field"    , validator="email"    , params={ validDomains = ["gmail.com"] }, message=""                          , serverCondition="${yet_another_field} eq 'test'", clientCondition="${yet_another_field}.val() === 'test'" }
			, { fieldName="yet_another_field", validator="maxLength", params={ maxLength = 87 }              , message="{bundle:some.resource.key}", serverCondition="", clientCondition="" }
		];

		FileWrite( filePath, SerializeJson( expected ) );

		ruleset = engine.newRuleset( name="notFussed", rules = filePath );

		super.assertEquals( expected, _rulesetToArrayOfStructs( ruleset.getRules() ) );
	}

	function test02_listRulesets_shouldReturnEmptyArray_whenNoRulesetsAreRegistered(){
		var engine = _getEngine();

		super.assertEquals( [], engine.listRulesets() );
	}

	function test03_listRulesets_shouldReturnArrayOfRegisteredRulesetNames(){
		var engine = _getEngine();

		engine.newRuleset( name="blah1" );
		engine.newRuleset( name="blah2" );
		engine.newRuleset( name="blah0" );

		super.assertEquals( [ "blah0", "blah1", "blah2" ], engine.listRulesets() );
	}

	function test04_listValidators_shouldReturnArrayOfCoreValidators_whenNoCustomValidatorsHaveBeenRegistered(){
		var engine         = _getEngine();
		var coreValidators = _listCoreValidators();

		super.assertEquals( coreValidators, engine.listValidators() );
	}

	function test05_newProvider_shouldReturnProviderObject_andRegisterAnyValidators_forThePassedComponent(){
		var engine             = _getEngine();
		var providerCfc        = new tests.resources.ValidationProvider.SimpleProvider();
		var provider           = engine.newProvider( sourceCfc = providerCfc );
		var expectedValidators = _listCoreValidators();

		ArrayAppend( expectedValidators, "validator1" );
		ArrayAppend( expectedValidators, "validator2" );
		ArrayAppend( expectedValidators, "validator3" );

		ArraySort( expectedValidators, "textnocase" );

		super.assertEquals( expectedValidators, engine.listValidators() );
		super.assert( IsInstanceOf( provider, "preside.system.services.validation.ValidationProvider" ) );
	}

	function test06_validate_shouldRunValidationRulesetAgainstDataAndFindErrors(){
		var engine = _getEngine();
		var ruleset = engine.newRuleset( name="testRuleset" );
		var result  = "";

		// test setup
		engine.newProvider( new tests.resources.ValidationProvider.SimpleProvider() );

		ruleset.addRule( fieldName="field1", validator="required", message="Not there" );
		ruleset.addRule( fieldName="field2", validator="validator1", params={justTesting=true}, serverCondition="IsDefined('${field2}')" );
		ruleset.addRule( fieldName="field3", validator="validator1", message="This should pass because of condition", serverCondition="${field2} eq 'I do not equal this'", params={justTesting=true} );
		ruleset.addRule( fieldName="field3", validator="required", message="Really not there" );

		// run the method we are testing
		result = engine.validate( ruleset="testRuleset", data={ field2="whatever" } );

		// check the expected result
		super.assertFalse( result.validated() );
		super.assertEquals( ["field1","field2","field3"], result.listErrorFields() );
		super.assertEquals( "Not there"             , result.getError( "field1" ) );
		super.assertEquals( "message for validator1", result.getError( "field2" ) );
		super.assertEquals( "Really not there"      , result.getError( "field3" ) );
		super.assertEquals( []    , result.listErrorParameterValues( "field1" ) );
		super.assertEquals( [true], result.listErrorParameterValues( "field2" ) );
		super.assertEquals( []    , result.listErrorParameterValues( "field3" ) );
	}

	function test07_validate_shouldThrowInformativeError_whenConditionalRuleDoesNotEvaluateToABoolean(){
		var engine = _getEngine();
		var ruleset = engine.newRuleset( name="testRuleset" );
		var errorThrown = false;

		ruleset.addRule( fieldName="field1", validator="required", message="Not there", serverCondition="theSky = 'blue'" );

		try {
			engine.validate( ruleset="testRuleset", data={} );
		} catch ( "ValidationEngine.badCondition" e ) {
			super.assertEquals( "The validator condition, [theSky = 'blue'], for field, [field1], did not evaulate to a boolean", e.message );
			errorThrown = true;
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test08_validate_shouldThrowInformativeError_whenConditionalRuleThrowsAnError(){
		var engine = _getEngine();
		var ruleset = engine.newRuleset( name="testRuleset" );
		var errorThrown = false;
		var aStruct = {};

		ruleset.addRule( fieldName="field1", validator="required", message="Not there", serverCondition="${field7} eq blue" );

		try {
			engine.validate( ruleset="testRuleset", data={} );
		} catch ( "ValidationEngine.badCondition" e ) {
			super.assertEquals( "The validator condition, [${field7} eq blue], for field, [field1], caused an exception to be raised. See error detail for more information.", e.message );

			try {
				Evaluate( "aStruct.field7 eq blue" );
			} catch( any e2 ) {
				super.assertEquals( "Message: [#e2.message#]. Detail: [#e2.detail#].", e.detail );

			}

			errorThrown = true;
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test09_getJQueryValidateJs_shouldReturnEmptyString_whenRulesetDoesNotExist(){
		var engine  = _getEngine();
		var ruleset = engine.newRuleset( name="testRuleset" );
		var result  = "";

		engine.newProvider( new tests.resources.ValidationProvider.SimpleProvider() );
		ruleset.addRule( fieldName="field1", validator="required", message="Not there" );
		ruleset.addRule( fieldName="field2", validator="validator1", params={justTesting=true} );
		ruleset.addRule( fieldName="field3", validator="required", message="Really not there" );

		super.assertEquals( "", engine.getJqueryValidateJs( ruleset="meh" ) );
	}

	function test10_getJQueryValidateJs_shouldReturnJsForGivenRuleset(){
		var engine   = _getEngine();
		var ruleset  = engine.newRuleset( name="testRuleset" );
		var result   = "";
		var expected = "";

		engine.newProvider( new tests.resources.ValidationProvider.SimpleProviderWithJsMethods() );
		ruleset.addRule( fieldName="field1", validator="required", message="Not there" );
		ruleset.addRule( fieldName="field1", validator="validator3", clientCondition="function( el ){ return ${field1}.val() === 'whatever'; }" );
		ruleset.addRule( fieldName="field2", validator="validator1", params={justTesting=true}, clientCondition="${field1}.val() === 'test'" );
		ruleset.addRule( fieldName="field3", validator="validator2", message="Really not there" );

		expected =  '( function( $ ){ ';
			expected &= 'var translateResource = ( i18n && i18n.translateResource ) ? i18n.translateResource : function(a){ return a }; ';
			expected &= '$.validator.addMethod( "validator3", function( value, element, params ){ return false; }, "" ); ';
			expected &= '$.validator.addMethod( "validator2", function( value, element, params ){ return true; }, "" ); ';
			expected &= 'return { ';
				expected &= 'rules : { ';
					expected &= '"field1" : { ';
						expected &= '"required" : { param : [] }, ';
						expected &= '"validator3" : { param : [], depends : function( el ){ return $( this.form ).find( "[name=''field1'']" ).val() === ''whatever''; } } ';
					expected &= '}, ';
					expected &= '"field2" : { ';
						expected &= '"validator1" : { param : [true], depends : function( element ){ return $( this.form ).find( "[name=''field1'']" ).val() === ''test''; } } ';
					expected &= '}, ';
					expected &= '"field3" : { ';
						expected &= '"validator2" : { param : ["test",false] } ';
					expected &= '} ';
				expected &= '}, ';
				expected &= 'messages : { ';
					expected &= '"field1" : { ';
						expected &= '"required" : translateResource( "Not there", { data : [] } ), ';
						expected &= '"validator3" : translateResource( "validation:another.message.key", { data : [] } ) ';
					expected &= '}, ';
					expected &= '"field2" : { ';
						expected &= '"validator1" : translateResource( "", { data : [true] } ) ';
					expected &= '}, ';
					expected &= '"field3" : { ';
						expected &= '"validator2" : translateResource( "Really not there", { data : ["test",false] } ) ';
					expected &= '} ';
				expected &= '} ';
			expected &= '}; ';
		expected &= '} )( presideJQuery )'

		super.assertEquals( expected, engine.getJqueryValidateJs( ruleset="testRuleset" ) );
	}

// PRIVATE
	private function _getEngine(){
		return new preside.system.services.validation.ValidationEngine();
	}

	private array function _listCoreValidators(){
		var providerCfc = new preside.system.services.validation.CoreValidators();
		var factory     = new preside.system.services.validation.ValidationProviderFactory();
		var provider    = factory.createProvider( providerCfc );

		return provider.listValidators();
	}

	private array function _rulesetToArrayOfStructs( rules ) output=false {
		var arrOfStructs = [];
		var rule = "";

		for( rule in arguments.rules ){
			ArrayAppend( arrOfStructs, rule.getMemento() );
		}

		return arrOfStructs;
	}

}