component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "getStandardRulesForFormField", function(){
			it( "should return an empty array when form field has no configuration", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="myfield" ) ).toBe( [] );
			} );

			it( "should return an array containing a 'required' rule when the field is mandatory", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="myfield", mandatory=true ) ).toBe( [
					{ fieldName="myfield", validator="required" }
				] );
			} );

			it( "should return an array containing a maxLength rule when there is a maxLength attribute that has a greater-than-zero value", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", mandatory=false, maxLength=30 ) ).toBe( [
					{ fieldName="testfield", validator="maxLength", params={ length=30 } }
				] );
			} );

			it( "should return an array that does NOT contain a maxLength rule when there is a maxLength attribute equal to zero", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", maxLength=0 ) ).toBe( [] );
			} );

			it( "should return an array containing a minLength rule when there is a minLength attribute that has a greater-than-zero value", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", mandatory=false, minLength=5 ) ).toBe( [
					{ fieldName="testfield", validator="minLength", params={ length=5 } }
				] );
			} );

			it( "should return an array that does NOT contain a minLength rule when there is a minLength attribute equal to zero", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", minLength=0 ) ).toBe( [] );
			} );

			it( "should return an array that contains a rangeLength validator when both minLength and maxLength are supplied and non-zero", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", mandatory=false, minLength=5, maxLength=30 ) ).toBe( [
					{ fieldName="testfield", validator="rangeLength", params={ minLength=5, maxLength=30 } }
				] );
			} );

			it( "should return an array containing a 'max' rule when there is a maxValue attribute that has a greater-than-zero value", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", mandatory=false, maxValue=30 ) ).toBe( [
					{ fieldName="testfield", validator="max", params={ max=30 } }
				] );
			} );

			it( "should return an array that does NOT contain a maxValue rule when there is a maxValue attribute equal to zero", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", maxValue=0 ) ).toBe( [] );
			} );

			it( "should return an array containing a 'min' rule when there is a minValue attribute that has a greater-than-zero value", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", mandatory=false, minValue=5 ) ).toBe( [
					{ fieldName="testfield", validator="min", params={ min=5 } }
				] );
			} );

			it( "should return an array that does NOT contain a minValue rule when there is a minValue attribute equal to zero", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", minValue=0 ) ).toBe( [] );
			} );

			it( "should return an array that contains a range validator when both minValue and maxValue are supplied and non-zero", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", mandatory=false, minValue=5, maxValue=30 ) ).toBe( [
					{ fieldName="testfield", validator="range", params={ min=5, max=30 } }
				] );
			} );
		} );

		describe( "getItemTypeSpecificRulesForFormField", function(){
			it( "should call a convention based handler action to get rules for the given item type", function(){
				var service       = getService();
				var itemType      = "testitemtype";
				var handlerAction = "formbuilder.item-types.#itemType#.getValidationRules";
				var rules         = [ "test", "test", "test" ];
				var itemconfig    = { test="test", name="test", blah=CreateUUId() };

				mockColdbox.$( "runEvent" ).$args(
					  event          = handlerAction
					, private        = true
					, prepostexempt  = true
					, eventArguments = { args = itemconfig }
				).$results( rules );

				expect( service.getItemTypeSpecificRulesForFormField( itemType=itemType, configuration=itemConfig ) ).toBe( rules );
			} );

			it( "should return an empty array when no item type specific ruleset generator handler exists", function(){
				var service       = getService();
				var itemType      = "testitemtype";
				var handlerAction = "formbuilder.item-types.#itemType#.getValidationRules";
				var itemconfig    = { test="test", name="test", blah=CreateUUId() };

				mockColdbox.$( "handlerExists" ).$args( handlerAction ).$results( false );
				mockColdbox.$( "runEvent", [ 1, 2, 3 ] );

				expect( service.getItemTypeSpecificRulesForFormField( itemType=itemType, configuration=itemConfig ) ).toBe( [] );
				expect( mockColdbox.$callLog().runEvent.len() ).toBe( 0 );
			} );

			it( "should return an empty array when no item type specific ruleset generator handler exists", function(){
				var service       = getService();
				var itemType      = "testitemtype";
				var handlerAction = "formbuilder.item-types.#itemType#.getValidationRules";
				var itemconfig    = { test="test", name="test", blah=CreateUUId() };

				mockColdbox.$( "handlerExists" ).$args( handlerAction ).$results( false );
				mockColdbox.$( "runEvent", [ 1, 2, 3 ] );

				expect( service.getItemTypeSpecificRulesForFormField( itemType=itemType, configuration=itemConfig ) ).toBe( [] );
				expect( mockColdbox.$callLog().runEvent.len() ).toBe( 0 );
			} );
		} );

		describe( "getRulesetForFormItems", function(){
			it( "should generate an array of rules for each form field item in the passed item array and register it with the validation engine, returning the name of the ruleset", function(){
				var service             = getService();
				var expectedRules       = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ];
				var expectedRulesetName = "formbuilderform." & LCase( Hash( SerializeJson( expectedRules ) ) );
				var items               = [{
					  id            = CreateUUId()
					, type          = { id="sometype", isFormField=true }
					, configuration = { blah=true, test=CreateUUId() }
					, standardRules = [ 1, 2, 3 ]
					, specificRules = [ 4, 5, 6 ]
				},{
					  id            = CreateUUId()
					, type          = { id="textinput", isFormField=true }
					, configuration = { blah=true, test=CreateUUId() }
					, standardRules = [ 7 ]
					, specificRules = []
				},{
					  id            = CreateUUId()
					, type          = { id="anothertype", isFormField=false }
					, configuration = { blah=true, test=CreateUUId() }
					, standardRules = [ 1, 2, 3 ]
					, specificRules = [ 4, 5, 6 ]
				},{
					  id            = CreateUUId()
					, type          = { id="sometype", isFormField=true }
					, configuration = { blah=true, test=CreateUUId() }
					, standardRules = [ 8, 9 ]
					, specificRules = [ 10 ]
				}];

				for( item in items ) {
					if ( item.type.isFormField ) {
						service.$( "getStandardRulesForFormField" ).$args( argumentCollection=item.configuration ).$results( item.standardRules );
						service.$( "getItemTypeSpecificRulesForFormField" ).$args( itemtype=item.type.id, configuration=item.configuration ).$results(  item.specificRules );
					}
				}

				mockValidationEngine.$( "newRuleset", expectedRules );

				expect( service.getRulesetForFormItems( items ) ).toBe( expectedRulesetName );
				expect( mockValidationEngine.$callLog().newRuleset.len() ).toBe( 1 );
				expect( mockValidationEngine.$callLog().newRuleset[1].name ).toBe( expectedRulesetName );
				expect( mockValidationEngine.$callLog().newRuleset[1].rules ).toBe( expectedRules );
			} );

			it( "should return an empty string and not register a ruleset when there are no rules", function(){
				var service             = getService();
				var expectedRules       = [];
				var expectedRulesetName = "";
				var items               = [{
					  id            = CreateUUId()
					, type          = { id="sometype", isFormField=true }
					, configuration = { blah=true, test=CreateUUId() }
					, standardRules = []
					, specificRules = []
				},{
					  id            = CreateUUId()
					, type          = { id="textinput", isFormField=true }
					, configuration = { blah=true, test=CreateUUId() }
					, standardRules = []
					, specificRules = []
				},{
					  id            = CreateUUId()
					, type          = { id="anothertype", isFormField=false }
					, configuration = { blah=true, test=CreateUUId() }
					, standardRules = []
					, specificRules = []
				},{
					  id            = CreateUUId()
					, type          = { id="sometype", isFormField=true }
					, configuration = { blah=true, test=CreateUUId() }
					, standardRules = []
					, specificRules = []
				}];

				for( item in items ) {
					if ( item.type.isFormField ) {
						service.$( "getStandardRulesForFormField" ).$args( argumentCollection=item.configuration ).$results( item.standardRules );
						service.$( "getItemTypeSpecificRulesForFormField" ).$args( itemtype=item.type.id, configuration=item.configuration ).$results(  item.specificRules );
					}
				}

				mockValidationEngine.$( "newRuleset", expectedRules );

				expect( service.getRulesetForFormItems( items ) ).toBe( expectedRulesetName );
				expect( mockValidationEngine.$callLog().newRuleset.len() ).toBe( 0 );
			} );
		} );

		describe( "validateFormSubmission", function(){
			it( "should put the passed submission data through validation for the validation ruleset for the given form builder items array", function(){
				var service          = getService();
				var ruleset          = "my.ruleset." & CreateUUId();
				var items            = [ "this", "is", "just", "dummy", "for", "test" ];
				var submissionData   = { this="is", just="a test", data=CreateUUId() };
				var validationResult = CreateEmptyMock( "preside.system.services.validation.ValidationResult" );

				service.$( "getRulesetForFormItems" ).$args( items=items ).$results( ruleset );
				mockValidationEngine.$( "validate" ).$args( ruleset=ruleset, data=submissionData ).$results( validationResult );

				expect( service.validateFormSubmission(
					  formItems      = items
					, submissionData = submissionData
				) ).toBe( validationResult );
			} );

			it( "should return an empty validation result if there are no validation rules for the form", function(){
				var service          = getService();
				var ruleset          = "";
				var items            = [ "this", "is", "just", "dummy", "for", "test" ];
				var submissionData   = { this="is", just="a test", data=CreateUUId() };
				var validationResult = CreateEmptyMock( "preside.system.services.validation.ValidationResult" );

				service.$( "getRulesetForFormItems" ).$args( items=items ).$results( ruleset );
				mockValidationEngine.$( "newValidationResult", validationResult );

				expect( service.validateFormSubmission(
					  formItems      = items
					, submissionData = submissionData
				) ).toBe( validationResult );
			} );
		} );
	}

// PRIVATE HELPERS
	private function getService() {
		variables.mockColdbox          = CreateStub();
		variables.mockValidationEngine = CreateEmptyMock( "preside.system.services.validation.ValidationEngine" );

		var service = CreateMock( object=new preside.system.services.formbuilder.FormBuilderValidationService(
			validationEngine = mockValidationEngine
		) );

		service.$( "$getColdbox", mockColdbox );
		mockColdbox.$( "handlerExists", true );

		return service;
	}
}