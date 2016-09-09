component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getExpression()", function(){
			it( "should return a structure representing the expression including translated label and expression text", function(){
				var service      = _getService();
				var expressionId = "userGroup.event_booking";
				var expected     = Duplicate( mockExpressions[ expressionId ] );

				expected.label = CreateUUId();
				expected.text  = CreateUUId();
				expected.id    = expressionId;

				service.$( "getExpressionLabel" ).$args( expressionId ).$results( expected.label );
				service.$( "getExpressionText"  ).$args( expressionId ).$results( expected.text  );

				expect( service.getExpression( expressionId ) ).toBe( expected );
			} );

			it( "should throw an informative error when the expression does not exist", function(){
				var service      = _getService();
				var expressionId = "non.existant";
				var errorThrown  = false;

				try {
					service.getExpression( expressionId );

				} catch( "preside.rule.expression.not.found" e ) {
					errorThrown = true;
					expect( e.message ).toBe( "The expression [#expressionId#] could not be found." );

				} catch( any e ) {
					fail( "An unexpected error was thrown, rather than a controlled error" );
				}

			} );

			it( "should add translated default labels to any defined fields in the expression", function(){
				var service      = _getService();
				var expressionId = "userGroup.user";
				var expected     = Duplicate( mockExpressions[ expressionId ] );

				expected.label = CreateUUId();
				expected.text  = CreateUUId();
				expected.id    = expressionId;
				expected.fields._is.defaultLabel = CreateUUId();

				service.$( "getExpressionLabel" ).$args( expressionId ).$results( expected.label );
				service.$( "getExpressionText"  ).$args( expressionId ).$results( expected.text  );
				service.$( "getDefaultFieldLabel").$args( expressionId, "_is" ).$results( expected.fields._is.defaultLabel );

				expect( service.getExpression( expressionId ) ).toBe( expected );
			} );
		} );

		describe( "getExpressionLabel()", function(){
			it( "should return a translated label using a convention based i18n URI based on the expression id", function(){
				var service      = _getService();
				var expressionId = "some.expression.here";
				var label        = CreateUUId();

				service.$( "$translateResource" ).$args( uri="rules.expressions.#expressionId#:label", defaultValue=expressionId ).$results( label )

				expect( service.getExpressionLabel( expressionId ) ).toBe( label );
			} );
		} );

		describe( "getExpressionText()", function(){
			it( "should return a translated expression text using a convention based i18n URI based on the expression id", function(){
				var service      = _getService();
				var expressionId = "some.expression.here";
				var text        = CreateUUId();

				service.$( "$translateResource" ).$args( uri="rules.expressions.#expressionId#:text", defaultValue=expressionId ).$results( text )

				expect( service.getExpressionText( expressionId ) ).toBe( text );
			} );
		} );

		describe( "getDefaultFieldLabel()", function(){
			it( "should return a translated field label using a convention based i18n URI that falls back to a default URI should no expression specific label exist", function(){
				var service      = _getService();
				var expressionId = "some.expression.here";
				var fieldName    = "myfield";
				var label        = CreateUUId();
				var defaultLabel = CreateUUId();

				service.$( "$translateResource" ).$args( uri="rules.fields:#fieldName#.label", defaultValue=fieldName ).$results( defaultLabel );
				service.$( "$translateResource" ).$args( uri="rules.expressions.#expressionId#:field.#fieldName#.label", defaultValue=defaultLabel ).$results( label );

				expect( service.getDefaultFieldLabel( expressionId, fieldName ) ).toBe( label );
			} );
		} );

		describe( "listExpressions()", function(){
			it( "should return an array of all expressions, ordered by translated expression label", function(){
				var service = _getService();
				var expressionIds = mockExpressions.keyArray();
				var labels = [];

				for( var id in expressionIds ){
					labels.append( CreateUUId() );
					service.$( "getExpression" ).$args( id ).$results( { id=id, label=labels[ labels.len() ], text="whatever", fields={}, contexts=[] } );
				}

				var expressions = service.listExpressions();
				var orderedExpressionLabels = [];
				var orderedExpressionIds    = [];

				for( var expression in expressions ) {
					orderedExpressionIds.append( expression.id );
					orderedExpressionLabels.append( expression.label );
				}

				expect( orderedExpressionLabels ).toBe( labels.sort( "textnocase" ) );
			} );

			it( "should filter expressions by context when a context is supplied, with 'global' context matching any context", function(){
				var service = _getService();
				var context = "request";
				var expressionIds = mockExpressions.keyArray();

				for( var id in expressionIds ){
					service.$( "getExpression" ).$args( id ).$results(
						{ id=id, label=id, text=id, fields={}, contexts=mockExpressions[id].contexts }
					);
				}

				var expressions = service.listExpressions( context=context );
				var returnedIds = [];
				for( var expression in expressions ) {
					returnedIds.append( expression.id );
				}

				expect( returnedIds ).toBe( [
					  "expression3.context1"
					, "expression7.context5"
					, "userGroup.event_booking"
					, "userGroup.user"
				] );
			} );
		} );

		describe( "evaluateExpression()", function(){
			it( "should return false when the return value of the expression's convention-based coldbox handler is false for the given in context, payload and configured fields", function(){
				var service      = _getService();
				var context      = "request";
				var fields       = { _is = false, test=CreateUUId() };
				var payload      = { test=CreateUUId() };
				var expressionId = "userGroup.user";
				var eventArgs    = {
					  context = context
					, payload = payload
				};

				eventArgs.append( fields );

				mockColdboxController.$( "runEvent" ).$args(
					  event          = "rules.expressions.#expressionId#.evaluateExpression"
					, private        = true
					, prepostExempt  = true
					, eventArguments = eventArgs
				).$results( false );

				service.$( "preProcessConfiguredFields" ).$args( expressionId, fields ).$results( fields );

				expect( service.evaluateExpression(
					  expressionId     = expressionId
					, context          = context
					, payload          = payload
					, configuredFields = fields
				) ).toBeFalse();
			} );

			it( "should return true when the return value of the expression's convention-based coldbox handler is true for the given in context, payload and configured fields", function(){
				var service      = _getService();
				var context      = "request";
				var fields       = { _is = false, test=CreateUUId() };
				var payload      = { test=CreateUUId() };
				var expressionId = "userGroup.user";
				var eventArgs    = {
					  context = context
					, payload = payload
				};

				eventArgs.append( fields );

				mockColdboxController.$( "runEvent" ).$args(
					  event          = "rules.expressions.#expressionId#.evaluateExpression"
					, private        = true
					, prepostExempt  = true
					, eventArguments = eventArgs
				).$results( true );

				service.$( "preProcessConfiguredFields" ).$args( expressionId, fields ).$results( fields );

				expect( service.evaluateExpression(
					  expressionId     = expressionId
					, context          = context
					, payload          = payload
					, configuredFields = fields
				) ).toBeTrue();
			} );

			it( "should throw an informative error when the expression does not exist", function(){
				var service      = _getService();
				var expressionId = "non.existant";
				var errorThrown  = false;

				try {
					service.evaluateExpression(
						  expressionId     = expressionId
						, context          = "whatev"
						, payload          = {}
						, configuredFields = {}
					);

				} catch( "preside.rule.expression.not.found" e ) {
					errorThrown = true;
					expect( e.message ).toBe( "The expression [#expressionId#] could not be found." );

				} catch( any e ) {
					fail( "An unexpected error was thrown, rather than a controlled error" );
				}
			} );

			it( "should throw an informative error when the expression does not support the given context", function(){
				var service      = _getService();
				var expressionId = "userGroup.event_booking";
				var errorThrown  = false;

				try {
					service.evaluateExpression(
						  expressionId     = expressionId
						, context          = "whatev"
						, payload          = {}
						, configuredFields = {}
					);

				} catch( "preside.rule.expression.invalid.context" e ) {
					errorThrown = true;
					expect( e.message ).toBe( "The expression [#expressionId#] cannot be used in the [whatev] context." );

				} catch( any e ) {
					fail( "An unexpected error was thrown, rather than a controlled error" );
				}
			} );
		} );

		describe( "isExpressionValid()", function(){
			it( "should return false when expression is not valid for the passed context", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();

				expect( service.isExpressionValid(
					  expressionId     = "userGroup.user"
					, fields           = {}
					, context          = "badcontext"
					, validationResult = validationResult
				) ).toBeFalse();
			} );

			it( "should set a general error message when expression is not valid for the passed context", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();

				service.isExpressionValid(
					  expressionId     = "userGroup.user"
					, fields           = {}
					, context          = "badcontext"
					, validationResult = validationResult
				);

				expect( validationResult.getGeneralMessage() ).toBe( "The [userGroup.user] expression cannot be used in the [badcontext] context" );
			} );

			it( "should return false when expression does not exist", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();

				expect( service.isExpressionValid(
					  expressionId     = CreateUUId()
					, fields           = {}
					, context          = "badcontext"
					, validationResult = validationResult
				) ).toBeFalse();
			} );

			it( "should set a general error message when expression does not exist", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();
				var expressionid     = CreateUUId();

				service.isExpressionValid(
					  expressionId     = expressionid
					, fields           = {}
					, context          = "badcontext"
					, validationResult = validationResult
				);

				expect( validationResult.getGeneralMessage() ).toBe( "The [#expressionid#] expression could not be found" );
			} );

			it( "should return false when fields are missing one or more required values", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();

				expect( service.isExpressionValid(
					  expressionId     = "expression3.context1"
					, fields           = { fubar=CreateUUId() }
					, context          = "badcontext"
					, validationResult = validationResult
				) ).toBeFalse();
			} );

			it( "should set a general error message when fields are missing one or more required values", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();

				service.isExpressionValid(
					  expressionId     = "expression3.context1"
					, fields           = { fubar=CreateUUId() }
					, context          = "badcontext"
					, validationResult = validationResult
				);

				expect( validationResult.getGeneralMessage() ).toBe( "The [expression3.context1] expression is missing one or more required fields" );
			} );
		} );

		describe( "preProcessConfiguredFields()", function(){
			it( "should put each configured field value through the fieldTypeService's prepareConfiguredFieldData() method", function(){
				var service          = _getService();
				var expressionId     = "some.expression";
				var expression       = { contexts=["webrequest"], fields={ fielda={fieldtype="typea", test=CreateUUId()}, fieldb={fieldtype="typeb", test=CreateUUId()}, fieldc={fieldtype="typec", test=CreateUUId()} } };
				var configuredFields = { fielda="valuea", fieldb="valueb", fieldc="valuec" };

				service.$( "_getRawExpression" ).$args( expressionId ).$results( expression );

				for( var i in [ "a", "b", "c" ] ) {
					mockFieldTypeService.$( "prepareConfiguredFieldData" ).$args(
						  fieldType          = "type" & i
						, fieldConfiguration = expression.fields[ "field" & i ]
						, savedValue         = configuredFields[ "field" & i ]
					).$results( "processed" & i );
				}

				expect( service.preProcessConfiguredFields( expressionId, configuredFields ) ).toBe( { fielda="processeda", fieldb="processedb", fieldc="processedc" } );
			} );
		} );
	}


// PRIVATE HELPERS
	private any function _getService( struct expressions=_getDefaultTestExpressions() ) {
		variables.mockReaderService     = CreateEmptyMock( "preside.system.services.rulesEngine.RulesEngineExpressionReaderService" );
		variables.mockFieldTypeService  = CreateEmptyMock( "preside.system.services.rulesEngine.RulesEngineFieldTypeService" );
		variables.mockDirectories       = [ "/dir1/expressions", "/dir2/expressions", "/dir3/expressions" ];
		variables.mockExpressions       = arguments.expressions;
		variables.mockColdboxController = CreateStub();
		mockReaderService.$( "getExpressionsFromDirectories" ).$args( mockDirectories ).$results( mockExpressions );

		var service = new preside.system.services.rulesEngine.RulesEngineExpressionService(
			  expressionReaderService    = mockReaderService
			, fieldTypeService           = mockFieldTypeService
			, expressionDirectories      = mockDirectories
		);

		service = createMock( object=service );

		service.$( "$getColdbox", mockColdboxController );

		return service;
	}

	private struct function _getDefaultTestExpressions() {
		return {
			  "userGroup.user"          = { fields={ "_is"={ expressionType="boolean", variation="isIsNot" } }, contexts=[ "request" ] }
			, "userGroup.event_booking" = { fields={}, contexts=[ "request" ] }
			, "expression3.context1"    = { fields={ text={ required=true } }, contexts=[ "global" ] }
			, "expression4.context2"    = { fields={}, contexts=[ "event_booking" ] }
			, "expression5.context3"    = { fields={}, contexts=[ "marketing" ] }
			, "expression6.context4"    = { fields={}, contexts=[ "workflow" ] }
			, "expression7.context5"    = { fields={}, contexts=[ "workflow", "test", "request" ] }
		};
	}

	private any function _newValidationResult() {
		return new preside.system.services.validation.ValidationResult();
	}

}