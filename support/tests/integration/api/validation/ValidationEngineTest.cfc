component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

	function test01_newRuleset_shouldReturnTheRulesetArray(){
		var engine = _getEngine();
		var ruleset = "";
		var filePath = ListAppend( GetTempDirectory(), CreateUUId() );
		var expected = [
			  { fieldName="another_field"    , validator="email"    , params={ validDomains = ["gmail.com"] }, message=""                          , serverCondition="${yet_another_field} eq 'test'", clientCondition="${yet_another_field}.val() === 'test'" }
			, { fieldName="yet_another_field", validator="maxLength", params={ maxLength = 87 }              , message="{bundle:some.resource.key}", serverCondition="", clientCondition="" }
		];

		FileWrite( filePath, SerializeJson( expected ) );

		ruleset = engine.newRuleset( name="notFussed", rules = filePath );

		super.assertEquals( expected, ruleset );
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
		var rules  = [
			  { fieldName="field1", validator="required", message="Not there" }
			, { fieldName="field2", validator="validator1", params={justTesting=true}, serverCondition="IsDefined('${field2}')" }
			, { fieldName="field3", validator="validator1", message="This should pass because of condition", serverCondition="${field2} eq 'I do not equal this'", params={justTesting=true} }
			, { fieldName="field3", validator="required", message="Really not there" }
		];
		var ruleset = engine.newRuleset( name="testRuleset", rules=rules );
		var result  = "";

		// test setup
		engine.newProvider( new tests.resources.ValidationProvider.SimpleProvider() );

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
		var ruleset = engine.newRuleset( name="testRuleset", rules=[ { fieldName="field1", validator="required", message="Not there", serverCondition="theSky = 'blue'" } ] );
		var errorThrown = false;

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
		var ruleset = engine.newRuleset( name="testRuleset", rules=[ { fieldName="field1", validator="required", message="Not there", serverCondition="${field7} eq blue" } ] );
		var errorThrown = false;
		var aStruct = {};

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
		var rules   = [
			  { fieldName="field1", validator="required", message="Not there" }
			, { fieldName="field2", validator="validator1", params={justTesting=true} }
			, { fieldName="field3", validator="required", message="Really not there" }
		];
		var ruleset = engine.newRuleset( name="testRuleset", rules=rules );
		var result  = "";

		engine.newProvider( new tests.resources.ValidationProvider.SimpleProvider() );

		super.assertEquals( "", engine.getJqueryValidateJs( ruleset="meh" ) );
	}

	function test10_getJQueryValidateJs_shouldReturnJsForGivenRuleset(){
		var engine   = _getEngine();
		var rules    = [
			  { fieldName="field1", validator="required", message="Not there" }
			, { fieldName="field1", validator="validator3", clientCondition="function( el ){ return ${field1}.val() === 'whatever'; }" }
			, { fieldName="field2", validator="validator1", params={justTesting=true}, clientCondition="${field1}.val() === 'test'" }
			, { fieldName="field3", validator="validator2", message="Really not there" }
		];
		var ruleset  = engine.newRuleset( name="testRuleset", rules=rules );
		var translations = [ CreateUUId(), CreateUUId(), CreateUUId(), CreateUUId() ];
		var result   = "";
		var expected = "";

		engine.newProvider( new tests.resources.ValidationProvider.SimpleProviderWithJsMethods() );

		engine.$( "$translateResource" ).$args( uri="Not there"                     , data=[]             ).$results( translations[ 1 ] );
		engine.$( "$translateResource" ).$args( uri="validation:another.message.key", data=[]             ).$results( translations[ 2 ] );
		engine.$( "$translateResource" ).$args( uri=""                              , data=[true]         ).$results( translations[ 3 ] );
		engine.$( "$translateResource" ).$args( uri="Really not there"              , data=["test",false] ).$results( translations[ 4 ] );

		expected =  '( function( $ ){ ';
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
						expected &= '"required" : "#translations[ 1 ]#", ';
						expected &= '"validator3" : "#translations[ 2 ]#" ';
					expected &= '}, ';
					expected &= '"field2" : { ';
						expected &= '"validator1" : "#translations[ 3 ]#" ';
					expected &= '}, ';
					expected &= '"field3" : { ';
						expected &= '"validator2" : "#translations[ 4 ]#" ';
					expected &= '} ';
				expected &= '} ';
			expected &= '}; ';
		expected &= '} )( presideJQuery )'

		super.assertEquals( expected, engine.getJqueryValidateJs( ruleset="testRuleset" ) );
	}

// PRIVATE
	private function _getEngine(){
		return getMockBox().createMock( object=new preside.system.services.validation.ValidationEngine() );
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