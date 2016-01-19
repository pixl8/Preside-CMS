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
					{ fieldName="testfield", validator="maxLength", params={ max=30 } }
				] );
			} );

			it( "should return an array that does NOT contain a maxLength rule when there is a maxLength attribute equal to zero", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", maxLength=0 ) ).toBe( [] );
			} );

			it( "should return an array containing a minLength rule when there is a minLength attribute that has a greater-than-zero value", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", mandatory=false, minLength=5 ) ).toBe( [
					{ fieldName="testfield", validator="minLength", params={ min=5 } }
				] );
			} );

			it( "should return an array that does NOT contain a minLength rule when there is a minLength attribute equal to zero", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", minLength=0 ) ).toBe( [] );
			} );

			it( "should return an array that contains a rangeLength validator when both minLength and maxLength are supplied and non-zero", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", mandatory=false, minLength=5, maxLength=30 ) ).toBe( [
					{ fieldName="testfield", validator="rangeLength", params={ min=5, max=30 } }
				] );
			} );

			it( "should return an array containing a maxValue rule when there is a maxValue attribute that has a greater-than-zero value", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", mandatory=false, maxValue=30 ) ).toBe( [
					{ fieldName="testfield", validator="maxValue", params={ max=30 } }
				] );
			} );

			it( "should return an array that does NOT contain a maxValue rule when there is a maxValue attribute equal to zero", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", maxValue=0 ) ).toBe( [] );
			} );

			it( "should return an array containing a minValue rule when there is a minValue attribute that has a greater-than-zero value", function(){
				var service = getService();

				expect( service.getStandardRulesForFormField( name="testfield", mandatory=false, minValue=5 ) ).toBe( [
					{ fieldName="testfield", validator="minValue", params={ min=5 } }
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
		} );
	}

// PRIVATE HELPERS
	private function getService() {
		var service = CreateMock( object=new preside.system.services.formbuilder.FormBuilderValidationService() );

		variables.mockColdbox = CreateStub();
		service.$( "$getColdbox", mockColdbox );
		mockColdbox.$( "handlerExists", true );

		return service;
	}
}