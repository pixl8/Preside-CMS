component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {

		describe( "getHandlerForFieldType()", function(){
			it( "should use convention to return name of handler to use for field type actions", function(){
				var service = _getService();

				expect( service.getHandlerForFieldType( "myfieldtype" ) ).toBe( "rules.fieldtypes.myfieldtype" );
			} );
		} );

		describe( "renderConfiguredField()", function(){
			it( "should use the field type's handler action, 'renderConfiguredField', to render the given input value + set of field type config options", function(){
				var service       = _getService();
				var handler       = "some.handler";
				var action        = handler & ".renderConfiguredField";
				var fieldType     = "mytype";
				var rendered      = CreateUUId();
				var inputValue    = CreateUUId();
				var configOptions = { test=CreateUUId() }

				service.$( "getHandlerForFieldType" ).$args( fieldType ).$results( handler );
				mockColdbox.$( "handlerExists" ).$args( action ).$results( true );
				mockColdbox.$( "runEvent" ).$args(
					  event          = action
					, private        = true
					, prepostExempt  = true
					, eventArguments = { value=inputValue, config=configOptions }
				).$results( rendered );

				expect( service.renderConfiguredField( fieldType, inputValue, configOptions ) ).toBe( rendered );

			} );

			it( "should return the raw value when no handler action exists for the field type with which to render the value", function(){
				var service       = _getService();
				var handler       = "some.handler";
				var action        = handler & ".renderConfiguredField";
				var fieldType     = "mytype";
				var rendered      = CreateUUId();
				var inputValue    = CreateUUId();
				var configOptions = { test=CreateUUId() }

				service.$( "getHandlerForFieldType" ).$args( fieldType ).$results( handler );
				mockColdbox.$( "handlerExists" ).$args( action ).$results( false );

				expect( service.renderConfiguredField( fieldType, inputValue, configOptions ) ).toBe( inputValue );
			} );
		} );

		describe( "renderConfigurationScreen()", function(){
			it( "should do things", function(){
				fail( "but we haven't yet implemented anything" );
			} );
		} );

		describe( "processConfigurationScreenSubmission()", function(){
			it( "should do things", function(){
				fail( "but we haven't yet implemented anything" );
			} );
		} );

		describe( "prepareConfiguredFieldData()", function(){
			it( "should do things", function(){
				fail( "but we haven't yet implemented anything" );
			} );
		} );

	}

// PRIVATE HELPERS
	private any function _getService() {
		var service = new preside.system.services.rulesEngine.RulesEngineFieldTypeService();

		variables.mockColdbox = createStub();

		service = createMock( object=service );

		service.$( "$getColdbox", mockColdbox );

		return service;
	}

}