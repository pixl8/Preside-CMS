component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getExpression()", function(){
			it( "should return a structure representing the expression including translated category, label and expression text", function(){
				var service      = _getService();
				var expressionId = "userGroup.event_booking";
				var expected     = Duplicate( mockExpressions[ expressionId ] );

				expected.label    = CreateUUId();
				expected.text     = CreateUUId();
				expected.id       = expressionId;
				expected.category = CreateUUId();

				service.$( "translateExpressionCategory" ).$args( mockExpressions[ expressionId ].category ).$results( expected.category );
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

				expected.label                   = CreateUUId();
				expected.text                    = CreateUUId();
				expected.id                      = expressionId;
				expected.category                = "default";
				expected.fields._is.defaultLabel = CreateUUId();

				service.$( "getExpressionLabel" ).$args( expressionId ).$results( expected.label );
				service.$( "getExpressionText"  ).$args( expressionId ).$results( expected.text  );
				service.$( "getDefaultFieldLabel").$args( expressionId, "_is" ).$results( expected.fields._is.defaultLabel );

				expect( service.getExpression( expressionId ) ).toBe( expected );
			} );

			it( "should pass context through to the 'getExpressionLabel' and 'getExpressionText' methods", function(){
				var service      = _getService();
				var expressionId = "userGroup.user";
				var expected     = Duplicate( mockExpressions[ expressionId ] );
				var context      = "blah";

				expected.label                   = CreateUUId();
				expected.text                    = CreateUUId();
				expected.id                      = expressionId;
				expected.category                = "default";
				expected.fields._is.defaultLabel = CreateUUId();

				service.$( "getExpressionLabel" ).$args( expressionId=expressionId, context=context ).$results( expected.label );
				service.$( "getExpressionText"  ).$args( expressionId=expressionId, context=context ).$results( expected.text  );
				service.$( "getDefaultFieldLabel").$args( expressionId, "_is" ).$results( expected.fields._is.defaultLabel );

				expect( service.getExpression( expressionId=expressionId, context=context ) ).toBe( expected );
			} );

			it( "should pass objectName through to the 'getExpressionLabel' and 'getExpressionText' methods", function(){
				var service      = _getService();
				var expressionId = "userGroup.user";
				var expected     = Duplicate( mockExpressions[ expressionId ] );
				var objectName   = "blah_blah";

				expected.label    = CreateUUId();
				expected.text     = CreateUUId();
				expected.id       = expressionId;
				expected.category = "default";
				expected.fields._is.defaultLabel = CreateUUId();

				service.$( "getExpressionLabel" ).$args( expressionId=expressionId, objectName=objectName ).$results( expected.label );
				service.$( "getExpressionText"  ).$args( expressionId=expressionId, objectName=objectName ).$results( expected.text  );
				service.$( "getDefaultFieldLabel").$args( expressionId, "_is" ).$results( expected.fields._is.defaultLabel );

				expect( service.getExpression( expressionId=expressionId, objectName=objectName ) ).toBe( expected );
			} );
		} );

		describe( "getExpressionLabel()", function(){
			it( "should return a translated label using the configured label handler action and defined args", function(){
				var expressions  = _getDefaultTestExpressions();
				var service      = _getService( expressions );
				var expressionId = "expression3.context1";
				var label        = CreateUUId();

				expressions[ expressionId ].labelHandlerArgs = { testThis=CreateUUId() };
				var eventArgs = Duplicate( expressions[ expressionId ].labelHandlerArgs );
				    eventArgs.append( { context="" } );

				mockColdboxController.$( "handlerExists" ).$args( expressions[ expressionId ].labelHandler ).$results( true );
				mockColdboxController.$( "runEvent" ).$args(
					  event          = expressions[ expressionId ].labelHandler
					, private        = true
					, prePostExempt  = true
					, eventArguments = eventArgs
				).$results( label );

				expect( service.getExpressionLabel( expressionId ) ).toBe( label );
			} );

			it( "should return a translated label using a convention based i18n URI based on the expression id when the label generating handler does not exist", function(){
				var service      = _getService();
				var expressionId = "expression3.context1";
				var label        = CreateUUId();

				mockColdboxController.$( "handlerExists" ).$args( "blah.blah.#expressionId#.getLabel" ).$results( false );

				service.$( "$translateResource" ).$args( uri="rules.expressions.#expressionId#:label", defaultValue=expressionId ).$results( label )

				expect( service.getExpressionLabel( expressionId ) ).toBe( label );
			} );
		} );

		describe( "getExpressionText()", function(){
			it( "should return a translated text using the configured text handler action and defined args", function(){
				var expressions  = _getDefaultTestExpressions();
				var service      = _getService( expressions );
				var expressionId = "expression3.context1";
				var label        = CreateUUId();

				expressions[ expressionId ].textHandlerArgs = { testThis=CreateUUId() };
				var eventArgs = Duplicate( expressions[ expressionId ].textHandlerArgs );
				    eventArgs.append( { context="" } );

				mockColdboxController.$( "handlerExists" ).$args( expressions[ expressionId ].textHandler ).$results( true );
				mockColdboxController.$( "runEvent" ).$args(
					  event          = expressions[ expressionId ].textHandler
					, private        = true
					, prePostExempt  = true
					, eventArguments = eventArgs
				).$results( label );

				expect( service.getExpressionText( expressionId ) ).toBe( label );
			} );

			it( "should return a translated expression text using a convention based i18n URI based on the expression id when the handler does not exist", function(){
				var service      = _getService();
				var expressionId = "expression7.context5";
				var text        = CreateUUId();

				mockColdboxController.$( "handlerExists" ).$args( "blah.blah.#expressionId#.getText" ).$results( false );

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
				var dummyExpressionDefinition = { fields={ "#fieldName#" = {} } };

				service.$( "_getRawExpression" ).$args( expressionId ).$results( dummyExpressionDefinition );
				service.$( "$translateResource" ).$args( uri="rules.fields:#fieldName#.label", defaultValue=fieldName ).$results( defaultLabel );
				service.$( "$translateResource" ).$args( uri="rules.expressions.#expressionId#:field.#fieldName#.label", defaultValue=defaultLabel ).$results( label );

				expect( service.getDefaultFieldLabel( expressionId, fieldName ) ).toBe( label );
			} );

			it( "should return a translated field label using a configured based i18n URI when field definition includes a defined defaultLabel", function(){
				var service                   = _getService();
				var expressionId              = "some.expression.here";
				var fieldName                 = "myfield";
				var label                     = CreateUUId();
				var dummyExpressionDefinition = { fields={ "#fieldName#" = { defaultLabel="blah:blah.blah" } } };

				service.$( "_getRawExpression" ).$args( expressionId ).$results( dummyExpressionDefinition );
				service.$( "$translateResource" ).$args( uri="blah:blah.blah", defaultValue="blah:blah.blah" ).$results( label );

				expect( service.getDefaultFieldLabel( expressionId, fieldName ) ).toBe( label );
			} );
		} );

		describe( "listExpressions()", function(){
			it( "should return an array of all expressions, ordered by translated category and expression label", function(){
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
					service.$( "getExpression" ).$args( expressionId=id, context=context ).$results(
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

			it( "should only return expressions that can be used as filters for the given object", function(){
				var service = _getService();
				var object  = "usergroup";
				var expressionIds = mockExpressions.keyArray();

				for( var id in expressionIds ){
					service.$( "getExpression" ).$args( expressionId=id, objectName=object ).$results(
						{ id=id, label=id, text=id, fields={}, contexts=mockExpressions[id].contexts }
					);
				}

				var expressions = service.listExpressions( filterObject=object );
				var returnedIds = [];
				for( var expression in expressions ) {
					returnedIds.append( expression.id );
				}

				expect( returnedIds ).toBe( [
					  "expression6.context4"
					, "userGroup.event_booking"
					, "userGroup.user"
				] );
			} );
		} );

		describe( "evaluateExpression()", function(){
			it( "should return false when the return value of the expression's convention-based coldbox handler is false for the given in context, payload and configured fields", function(){
				var service      = _getService();
				var expressions  = _getDefaultTestExpressions();
				var context      = "request";
				var fields       = { _is = false, test=CreateUUId() };
				var payload      = { test=CreateUUId() };
				var expressionId = "userGroup.user";
				var eventArgs    = {
					  context    = context
					, payload    = payload
				};

				eventArgs.append( fields );

				mockColdboxController.$( "runEvent" ).$args(
					  event          = expressions[ expressionId ].expressionHandler
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

			it( "should return true when the return value of the expression's convention-based coldbox handler is true for the given context, payload and configured fields", function(){
				var service      = _getService();
				var expressions  = _getDefaultTestExpressions();
				var context      = "request";
				var fields       = { _is = false, test=CreateUUId() };
				var payload      = { test=CreateUUId() };
				var expressionId = "userGroup.user";
				var eventArgs    = {
					  context    = context
					, payload    = payload
				};

				eventArgs.append( fields );

				mockColdboxController.$( "runEvent" ).$args(
					  event          = expressions[ expressionId ].expressionHandler
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

			it( "should return false and raise an informative error when the expression does not exist", function(){
				var service      = _getService();
				var expressionId = "non.existant";
				var errorThrown  = false;

				service.$( "$raiseError" );

				expect( service.evaluateExpression(
					  expressionId     = expressionId
					, context          = "whatev"
					, payload          = {}
					, configuredFields = {}
				) ).toBe( false );

				var callLog = service.$callLog().$raiseError;

				expect( callLog.len() ).toBe( 1 );
				var error = callLog[ 1 ][ 1 ] ?: {};
				expect( error.type ?: "" ).toBe( "preside.rule.expression.not.found" );
				expect( error.message ?: "" ).toBe( "The expression [#expressionId#] could not be found." );
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

			it( "should append any pre-defined expression arguments for the expression to the arguments passed to the expression handler", function(){
				var expressions  = _getDefaultTestExpressions();
				var expressionId = "userGroup.user";
				expressions[ expressionId ].expressionHandlerArgs = {
					  test = CreateUUId()
					, boo  = "hoo"
				};

				var service      = _getService( expressions );
				var context      = "request";
				var fields       = { _is = false, test=CreateUUId() };
				var payload      = { test=CreateUUId() };
				var eventArgs    = {
					  context    = context
					, payload    = payload
				};

				eventArgs.append( expressions[ expressionId ].expressionHandlerArgs );
				eventArgs.append( fields );

				mockColdboxController.$( "runEvent" ).$args(
					  event          = expressions[ expressionId ].expressionHandler
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

		describe( "prepareExpressionFilters()", function(){
			it( "should return result of 'prepareFilters()' method with expression configuration passed as arguments", function(){
				var service      = _getService();
				var expressions  = _getDefaultTestExpressions();
				var objectName   = "usergroup";
				var dummyFilters = [ 1, 2, 3, "test", CreateUUId() ];
				var fields       = { _is = false, test=CreateUUId() };
				var expressionId = "userGroup.user";
				var eventArgs    = { objectName = objectName, filterPrefix="" };

				eventArgs.append( fields );

				mockColdboxController.$( "runEvent" ).$args(
					  event          = expressions[ expressionId ].filterHandler
					, private        = true
					, prepostExempt  = true
					, eventArguments = eventArgs
				).$results( dummyFilters );

				service.$( "preProcessConfiguredFields" ).$args( expressionId, fields ).$results( fields );

				expect( service.prepareExpressionFilters(
					  expressionId     = expressionId
					, objectName       = objectName
					, configuredFields = fields
				) ).toBe( dummyFilters );
			} );

			it( "should append any defined filter args to the arguments passed to the 'prepareFilters()' handler", function(){
				var expressions  = _getDefaultTestExpressions();
				var service      = _getService( expressions );
				var expressionId = "userGroup.user";

				expressions[ expressionId ].filterHandlerArgs = {
					  test = CreateUUId()
					, tea  = Now()
				};

				var objectName   = "usergroup";
				var dummyFilters = [ 1, 2, 3, "test", CreateUUId() ];
				var fields       = { _is = false, test=CreateUUId() };
				var eventArgs    = { objectName = objectName, filterPrefix="" };

				eventArgs.append( expressions[ expressionId ].filterHandlerArgs );
				eventArgs.append( fields );

				mockColdboxController.$( "runEvent" ).$args(
					  event          = expressions[ expressionId ].filterHandler
					, private        = true
					, prepostExempt  = true
					, eventArguments = eventArgs
				).$results( dummyFilters );

				service.$( "preProcessConfiguredFields" ).$args( expressionId, fields ).$results( fields );

				expect( service.prepareExpressionFilters(
					  expressionId     = expressionId
					, objectName       = objectName
					, configuredFields = fields
				) ).toBe( dummyFilters );
			} );

			it( "should pass through a 'filterPrefix' argument to the handler when supplied to the method", function(){
				var expressions  = _getDefaultTestExpressions();
				var service      = _getService( expressions );
				var expressionId = "userGroup.user";
				var filterPrefix = CreateUUId();

				expressions[ expressionId ].filterHandlerArgs = {
					  test = CreateUUId()
					, tea  = Now()
				};

				var objectName   = "usergroup";
				var dummyFilters = [ 1, 2, 3, "test", CreateUUId() ];
				var fields       = { _is = false, test=CreateUUId() };
				var eventArgs    = { objectName = objectName };

				eventArgs.append( expressions[ expressionId ].filterHandlerArgs );
				eventArgs.append( fields );
				eventArgs.filterPrefix = filterPrefix

				mockColdboxController.$( "runEvent" ).$args(
					  event          = expressions[ expressionId ].filterHandler
					, private        = true
					, prepostExempt  = true
					, eventArguments = eventArgs
				).$results( dummyFilters );

				service.$( "preProcessConfiguredFields" ).$args( expressionId, fields ).$results( fields );

				expect( service.prepareExpressionFilters(
					  expressionId     = expressionId
					, objectName       = objectName
					, configuredFields = fields
					, filterPrefix     = filterPrefix
				) ).toBe( dummyFilters );
			} );

			it( "should append 'parentPropertyName' to the 'filterPrefix' when present in the filter args", function(){
				var expressions  = _getDefaultTestExpressions();
				var service      = _getService( expressions );
				var expressionId = "userGroup.user";
				var filterPrefix = CreateUUId();

				expressions[ expressionId ].filterHandlerArgs = {
					  test               = CreateUUId()
					, tea                = Now()
					, parentPropertyName = "test"
				};

				var objectName   = "usergroup";
				var dummyFilters = [ 1, 2, 3, "test", CreateUUId() ];
				var fields       = { _is = false, test=CreateUUId() };
				var eventArgs    = { objectName = objectName };

				eventArgs.append( expressions[ expressionId ].filterHandlerArgs );
				eventArgs.append( fields );
				eventArgs.filterPrefix = filterPrefix & "$test";

				mockColdboxController.$( "runEvent" ).$args(
					  event          = expressions[ expressionId ].filterHandler
					, private        = true
					, prepostExempt  = true
					, eventArguments = eventArgs
				).$results( dummyFilters );

				service.$( "preProcessConfiguredFields" ).$args( expressionId, fields ).$results( fields );

				expect( service.prepareExpressionFilters(
					  expressionId     = expressionId
					, objectName       = objectName
					, configuredFields = fields
					, filterPrefix     = filterPrefix
				) ).toBe( dummyFilters );
			} );

			it( "should throw an informative error when the expression does not exist", function(){
				var service      = _getService();
				var expressionId = "non.existant";
				var errorThrown  = false;

				try {
					service.prepareExpressionFilters(
						  expressionId     = expressionId
						, objectName       = "whatev"
						, configuredFields = {}
					);

				} catch( "preside.rule.expression.not.found" e ) {
					errorThrown = true;
					expect( e.message ).toBe( "The expression [#expressionId#] could not be found." );

				} catch( any e ) {
					fail( "An unexpected error was thrown, rather than a controlled error" );
				}
				expect( errorThrown ).toBe( true );
			} );

			it( "should throw an informative error when the expression does not support filtering the given object", function(){
				var service      = _getService();
				var expressionId = "userGroup.event_booking";
				var errorThrown  = false;

				try {
					service.prepareExpressionFilters(
						  expressionId     = expressionId
						, objectName       = "whatev"
						, configuredFields = {}
					);

				} catch( "preside.rule.expression.invalid.filter.object" e ) {
					errorThrown = true;
					expect( e.message ).toBe( "The expression [#expressionId#] cannot be used to filter the [whatev] object." );

				} catch( any e ) {
					fail( "An unexpected error was thrown, rather than a controlled error" );
				}
				expect( errorThrown ).toBe( true );
			} );
		} );

		describe( "addExpression()", function(){
			it( "should result in the added expression (defined by arguments) being available in the expression library", function(){
				var service      = _getService();
				var expressionIds = mockExpressions.keyArray();
				var newExpression = {
					  id                    = "some.expression"
					, contexts              = [ "context1" ]
					, fields                = {}
					, filterObjects         = [ "object1", "object2" ]
					, expressionHandler     = "blah"
					, filterHandler         = "blahblah"
					, labelHandler          = "blahblahblah"
					, textHandler           = "blahblahblahblah"
					, expressionHandlerArgs = {}
					, filterHandlerArgs     = {}
					, labelHandlerArgs      = {}
					, textHandlerArgs       = {}
				};
				expressionIds.append( newExpression.id );

				for( var id in expressionIds ){
					service.$( "getExpression" ).$args( id ).$results( { id=id, label="whatev", text="whatever", fields={}, contexts=[] } );
				}

				service.addExpression( argumentCollection=newExpression );

				var expressions = service.listExpressions();
				var ids         = [];

				for( var expression in expressions ) {
					ids.append( expression.id );
				}

				expect( ids.findNoCase( newExpression.id ) > 0 ).toBe( true );
			} );
		} );

		describe( "getFilterObjectsForExpression()", function(){
			it( "should return the array of configured filter objects for the given expression", function(){
				var service = _getService();

				expect( service.getFilterObjectsForExpression( "expression6.context4" ) ).toBe( [ "objectz", "usergroup" ] );
			} );
		} );
	}


// PRIVATE HELPERS
	private any function _getService( struct expressions=_getDefaultTestExpressions() ) {
		variables.mockReaderService       = CreateEmptyMock( "preside.system.services.rulesEngine.RulesEngineExpressionReaderService" );
		variables.mockFieldTypeService    = CreateEmptyMock( "preside.system.services.rulesEngine.RulesEngineFieldTypeService" );
		variables.mockContextService      = CreateEmptyMock( "preside.system.services.rulesEngine.RulesEngineContextService" );
		variables.mockExpressionGenerator = CreateEmptyMock( "preside.system.services.rulesEngine.RulesEngineAutoPresideObjectExpressionGenerator" );
		variables.mockDirectories         = [ "/dir1/expressions", "/dir2/expressions", "/dir3/expressions" ];
		variables.mockI18n                = createStub();
		variables.mockExpressions         = arguments.expressions;
		variables.mockColdboxController   = CreateStub();
		mockReaderService.$( "getExpressionsFromDirectories" ).$args( mockDirectories ).$results( mockExpressions );
		mockI18n.$( "getFWLanguageCode" ).$results( "en" );
		mockI18n.$( "getFWCountryCode" ).$results( "" );

		var service = new preside.system.services.rulesEngine.RulesEngineExpressionService(
			  expressionReaderService    = mockReaderService
			, contextService             = mockContextService
			, fieldTypeService           = mockFieldTypeService
			, expressionDirectories      = mockDirectories
			, autoExpressionGenerator    = mockExpressionGenerator
			, i18n                       = mockI18n
		);

		service = createMock( object=service );

		service.$( "$getColdbox", mockColdboxController );
		service.$( "_lazyLoadDynamicExpressions" );
		mockContextService.$( "getContextObject" ).$args( "request" ).$results( "request_object" );
		mockContextService.$( "getContextObject" ).$args( "" ).$results( "" );
		service.$( "translateExpressionCategory", "default" );

		return service;
	}

	private struct function _getDefaultTestExpressions() {
		var expressions = {
			  "userGroup.user"          = { fields={ "_is"={ expressionType="boolean", variation="isIsNot" } }, contexts=[ "request" ], filterObjects=[ "usergroup" ], category="blah" }
			, "userGroup.event_booking" = { fields={}, contexts=[ "request" ], filterObjects=[ "usergroup" ], category="blah" }
			, "expression3.context1"    = { fields={ text={ required=true } }, contexts=[ "global" ], filterObjects=[ "objectx" ], category="blah" }
			, "expression4.context2"    = { fields={}, contexts=[ "event_booking" ], filterObjects=[ "objecty" ], category="blah" }
			, "expression5.context3"    = { fields={}, contexts=[ "marketing" ], filterObjects=[ "objectx" ], category="blah" }
			, "expression6.context4"    = { fields={}, contexts=[ "workflow" ], filterObjects=[ "objectz", "usergroup" ], category="blah" }
			, "expression7.context5"    = { fields={}, contexts=[ "workflow", "test", "request" ], filterObjects=[ ], category="blah" }
		};

		for( var expressionId in expressions ) {
			expressions[ expressionId ].append({
				  expressionHandler     = "blah.blah.#expressionId#.evaluateExpression"
				, filterHandler         = "blah.blah.#expressionId#.prepareFilters"
				, labelHandler          = "blah.blah.#expressionId#.getLabel"
				, textHandler           = "blah.blah.#expressionId#.getText"
				, expressionHandlerArgs = {}
				, filterHandlerArgs     = {}
				, i18nLabelArgs         = {}
				, i18nTextArgs          = {}
			});
		}

		return expressions;
	}

	private any function _newValidationResult() {
		return new preside.system.services.validation.ValidationResult();
	}

}