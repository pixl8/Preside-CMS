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

				expect( service.renderConfiguredField( fieldType=fieldType, value=inputValue, fieldConfiguration=configOptions ) ).toBe( rendered );

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

				expect( service.renderConfiguredField( fieldType=fieldType, value=inputValue, fieldConfiguration=configOptions ) ).toBe( inputValue );
			} );
		} );

		describe( "renderConfigScreen()", function(){
			it( "should use the field type's viewlet, 'renderConfigScreen', to render the field type's configuration screen", function(){
				var service       = _getService();
				var handler       = "some.handler";
				var action        = handler & ".renderConfigScreen";
				var fieldType     = "mytype";
				var rendered      = CreateUUId();
				var savedValue    = CreateUUId();
				var configOptions = { test=CreateUUId() }

				service.$( "getHandlerForFieldType" ).$args( fieldType ).$results( handler );
				mockColdbox.$( "handlerExists" ).$args( action ).$results( true );
				mockColdbox.$( "runEvent" ).$args(
					  event          = action
					, private        = true
					, prepostExempt  = true
					, eventArguments = { value=savedValue, config=configOptions }
				).$results( rendered );

				expect( service.renderConfigScreen(
					  fieldType          = fieldType
					, currentValue       = savedValue
					, fieldConfiguration = configOptions
				) ).toBe( rendered );
			} );

			it( "should throw an informative error when the field type has no 'renderConfigScreen' handler", function(){
				var service     = _getService();
				var handler     = "some.handler";
				var action      = handler & ".renderConfigScreen";
				var fieldType   = "mytype";
				var errorThrown = false;

				service.$( "getHandlerForFieldType" ).$args( fieldType ).$results( handler );
				mockColdbox.$( "handlerExists" ).$args( action ).$results( false );

				try {
					service.renderConfigScreen(
						  fieldType          = fieldType
						, currentValue       = ""
						, fieldConfiguration = {}
					);
				} catch( "preside.rules.fieldtype.missing.config.screen" e ) {
					errorThrown = true;
					expect( e.message ).toBe( "The field type, [#fieldType#], has no [renderConfigScreen] handler with which to show a configuration screen" );
				} catch( any e ) {
					fail( "A specific and helpful error message was not thrown. Instead: [#e.message#]" );
				}

				expect( errorThrown ).toBe( true );
			} );
		} );

		describe( "processConfigScreenSubmission()", function(){
			it( "should use the field type's handler action, 'processConfigScreenSubmission', to retrieve a value for the field based on a submission", function(){
				var service          = _getService();
				var handler          = "some.handler";
				var action           = handler & ".processConfigScreenSubmission";
				var fieldType        = "mytype";
				var result           = { test=CreateUUId() };
				var configOptions    = { test=CreateUUId() };
				var validationResult = CreateStub();

				service.$( "getHandlerForFieldType" ).$args( fieldType ).$results( handler );
				mockColdbox.$( "handlerExists" ).$args( action ).$results( true );
				mockColdbox.$( "runEvent" ).$args(
					  event          = action
					, private        = true
					, prepostExempt  = true
					, eventArguments = { config=configOptions, validationResult=validationResult }
				).$results( result );

				expect( service.processConfigScreenSubmission(
					  fieldType          = fieldType
					, fieldConfiguration = configOptions
					, validationResult   = validationResult
				) ).toBe( result );
			} );

			it( "should throw an informative error when the field type has no 'processConfigScreenSubmission' handler", function(){
				var service     = _getService();
				var handler     = "some.handler";
				var action      = handler & ".processConfigScreenSubmission";
				var fieldType   = "mytype";
				var errorThrown = false;

				service.$( "getHandlerForFieldType" ).$args( fieldType ).$results( handler );
				mockColdbox.$( "handlerExists" ).$args( action ).$results( false );

				try {
					service.processConfigScreenSubmission(
						  fieldType          = fieldType
						, validationResult   = CreateStub()
						, fieldConfiguration = {}
					);
				} catch( "preside.rules.fieldtype.missing.config.action" e ) {
					errorThrown = true;
					expect( e.message ).toBe( "The field type, [#fieldType#], has no [processConfigScreenSubmission] handler with which to process config screen submission" );
				} catch( any e ) {
					fail( "A specific and helpful error message was not thrown. Instead: [#e.message#]" );
				}

				expect( errorThrown ).toBe( true );
			} );
		} );

		describe( "prepareConfiguredFieldData()", function(){
			it( "should use the field type's handler action, 'prepareConfiguredFieldData', to retrieve a 'live' value for the saved field value within an expression", function(){
				var service          = _getService();
				var handler          = "some.handler";
				var action           = handler & ".prepareConfiguredFieldData";
				var fieldType        = "mytype";
				var result           = { test=CreateUUId() };
				var configOptions    = { test=CreateUUId() };
				var savedValue       = { blah=CreateUUId() };

				service.$( "getHandlerForFieldType" ).$args( fieldType ).$results( handler );
				mockColdbox.$( "handlerExists" ).$args( action ).$results( true );
				mockColdbox.$( "runEvent" ).$args(
					  event          = action
					, private        = true
					, prepostExempt  = true
					, eventArguments = { config=configOptions, value=savedValue }
				).$results( result );

				expect( service.prepareConfiguredFieldData(
					  fieldType          = fieldType
					, fieldConfiguration = configOptions
					, savedValue         = savedValue
				) ).toBe( result );
			} );

			it( "should return the raw saved value when the field type has not implemented a 'prepareConfiguredFieldData' handler action", function(){
				var service          = _getService();
				var handler          = "some.handler";
				var action           = handler & ".prepareConfiguredFieldData";
				var fieldType        = "mytype";
				var result           = { test=CreateUUId() };
				var configOptions    = { test=CreateUUId() };
				var savedValue       = { blah=CreateUUId() };

				service.$( "getHandlerForFieldType" ).$args( fieldType ).$results( handler );
				mockColdbox.$( "handlerExists" ).$args( action ).$results( false );

				expect( service.prepareConfiguredFieldData(
					  fieldType          = fieldType
					, fieldConfiguration = configOptions
					, savedValue         = savedValue
				) ).toBe( savedValue );
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