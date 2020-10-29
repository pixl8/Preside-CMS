component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getCondition()", function(){
			it( "should return a deSerialized expression from database lookup of serialized expression by ID", function(){
				var service     = _getService();
				var conditionId = CreateUUId();
				var expressions = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];
				var dbRecord    = QueryNew( "id,condition_name,context,expressions", "varchar,varchar,varchar,varchar", [[
					conditionId, "My Condition", "visitor", SerializeJson( expressions )
				]] );


				mockConditionDao.$( "selectData" ).$args( id=conditionId ).$results( dbRecord );

				expect( service.getCondition( conditionId ) ).toBe( {
					  id          = conditionId
					, name        = dbRecord.condition_name
					, context     = dbRecord.context
					, expressions = expressions
				} );

			} );

			it( "should return an empty struct when the condition does not exist", function(){
				var service     = _getService();
				var conditionId = CreateUUId();
				var dbRecord    = QueryNew( "id,condition_name,context,expressions" );

				mockConditionDao.$( "selectData" ).$args( id=conditionId ).$results( dbRecord );

				expect( service.getCondition( conditionId ) ).toBe( {} );
			} );
		} );

		describe( "validateCondition()", function(){
			it( "should return false when passed condition is not valid JSON", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();

				expect( service.validateCondition(
					  condition        = "{lsakjdfljd.test"
					, validationResult = validationResult
					, context          = "any"
				) ).toBeFalse();
			} );

			it( "should add a general validation result error explaining invalid JSON packet error when condition is invalid json", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();

				service.validateCondition(
					  condition        = "{lsakjdfljd.test"
					, validationResult = validationResult
					, context          = "any"
				);

				expect( validationResult.getGeneralMessage() ).toBe( "The passed condition was malformed and could not be read" );
			} );

			it( "should return false when passed JSON condition does not evaluate to an array", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();

				expect( service.validateCondition(
					  condition        = "{ ""test"":true }"
					, validationResult = validationResult
					, context          = "any"
				) ).toBeFalse();
			} );

			it( "should add a general validation result error explaining condition is malformed when passed JSON condition does not evaluate to an array", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();

				service.validateCondition(
					  condition        = "{ ""test"":true }"
					, validationResult = validationResult
					, context          = "any"
				);

				expect( validationResult.getGeneralMessage() ).toBe( "The passed condition was malformed and could not be read" );
			} );

			it( "should return false when an item in an odd row is a simple value", function(){
				var service              = _getService();
				var validationResult     = _newValidationResult();
				var badlyFormedCondition = SerializeJson( [
					{ "expression":"event.attendance", "fields":{} },
					"or",
					"blah",
					[
						{ "expression":"has.membership", "fields":{} },
						"and",
						{ "expression":"user.visits", "fields":{} },
						"and",
						[
							{ "expression":"user.spend", "fields":{} },
							"or",
							{ "expression":"found.egg", "fields":{} }
						]
					],
					"and",
					"or", // expect either an expression or expression group here
					{ "expression":"is.legend", "fields":{} }
				] );

				expect( service.validateCondition(
					  condition        = badlyFormedCondition
					, validationResult = validationResult
					, context          = "any"
				) ).toBeFalse();
			} );

			it( "should add a general validation result error explaining condition is malformed when an item in an odd row is a simple value", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();
				var badlyFormedCondition = SerializeJson( [
					{ "expression":"event.attendance", "fields":{} },
					"or",
					"blah",
					[
						{ "expression":"has.membership", "fields":{} },
						"and",
						{ "expression":"user.visits", "fields":{} },
						"and",
						[
							{ "expression":"user.spend", "fields":{} },
							"or",
							{ "expression":"found.egg", "fields":{} }
						]
					],
					"and",
					"or", // expect either an expression or expression group here
					{ "expression":"is.legend", "fields":{} }
				] );

				service.validateCondition(
					  condition        = badlyFormedCondition
					, validationResult = validationResult
					, context          = "any"
				);

				expect( validationResult.getGeneralMessage() ).toBe( "The passed condition was malformed and could not be read" );
			} );

			it( "should return false when passed condition has a simple value in an even row that is neither 'and' or 'or'", function(){
				var service              = _getService();
				var validationResult     = _newValidationResult();
				var badlyFormedCondition = SerializeJson( [
					{ "expression":"event.attendance", "fields":{} },
					"or",
					[
						{ "expression":"has.membership", "fields":{} },
						"and",
						{ "expression":"user.visits", "fields":{} },
						"and",
						[
							{ "expression":"user.spend", "fields":{} },
							"fubar",
							{ "expression":"found.egg", "fields":{} }
						]
					],
					"and",
					{ "expression":"is.legend", "fields":{} }
				] );

				expect( service.validateCondition(
					  condition        = badlyFormedCondition
					, validationResult = validationResult
					, context          = "any"
				) ).toBeFalse();
			} );

			it( "should add a general validation result error explaining condition is malformed when passed condition has a simple value in an even row that is neither 'and' or 'or'", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();
				var badlyFormedCondition = SerializeJson( [
					{ "expression":"event.attendance", "fields":{} },
					"or",
					[
						{ "expression":"has.membership", "fields":{} },
						"and",
						{ "expression":"user.visits", "fields":{} },
						"and",
						[
							{ "expression":"user.spend", "fields":{} },
							"fubar",
							{ "expression":"found.egg", "fields":{} }
						]
					],
					"and",
					{ "expression":"is.legend", "fields":{} }
				] );

				service.validateCondition(
					  condition        = badlyFormedCondition
					, validationResult = validationResult
					, context          = "any"
				);

				expect( validationResult.getGeneralMessage() ).toBe( "The passed condition was malformed and could not be read" );
			} );

			it( "should return false when passed condition has an item in an even row that is not a simple value", function(){
				var service              = _getService();
				var validationResult     = _newValidationResult();
				var badlyFormedCondition = SerializeJson( [
					{ "expression":"event.attendance", "fields":{} },
					"or",
					[
						{ "expression":"has.membership", "fields":{} },
						"and",
						{ "expression":"user.visits", "fields":{} },
						"and",
						[
							{ "expression":"user.spend", "fields":{} },
							{ "test" : true },
							{ "expression":"found.egg", "fields":{} }
						]
					],
					"and",
					{ "expression":"is.legend", "fields":{} }
				] );

				expect( service.validateCondition(
					  condition        = badlyFormedCondition
					, validationResult = validationResult
					, context          = "any"
				) ).toBeFalse();
			} );

			it( "should add a general validation result error explaining condition is malformed when passed condition has an item in an even row that is not a simple value", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();
				var badlyFormedCondition = SerializeJson( [
					{ "expression":"event.attendance", "fields":{} },
					"or",
					[
						{ "expression":"has.membership", "fields":{} },
						"and",
						{ "expression":"user.visits", "fields":{} },
						"and",
						[
							{ "expression":"user.spend", "fields":{} },
							{ "test" : true },
							{ "expression":"found.egg", "fields":{} }
						]
					],
					"and",
					{ "expression":"is.legend", "fields":{} }
				] );

				service.validateCondition(
					  condition        = badlyFormedCondition
					, validationResult = validationResult
					, context          = "any"
				);

				expect( validationResult.getGeneralMessage() ).toBe( "The passed condition was malformed and could not be read" );
			} );


			it( "should return false when passed condition has an item in an odd row that is a struct but does not have 'expression' and 'fields' keys", function(){
				var service              = _getService();
				var validationResult     = _newValidationResult();
				var badlyFormedCondition = SerializeJson( [
					{ "expression":"event.attendance", "fields":{} },
					"or",
					[
						{ "expression":"has.membership", "fields":{} },
						"and",
						{ "expression":"user.visits", "fields":{} },
						"and",
						[
							{ "test":true },
							"and",
							{ "expression":"found.egg", "fields":{} }
						]
					],
					"and",
					{ "expression":"is.legend", "fields":{} }
				] );

				expect( service.validateCondition(
					  condition        = badlyFormedCondition
					, validationResult = validationResult
					, context          = "any"
				) ).toBeFalse();
			} );

			it( "should add a general validation result error explaining condition is malformed when passed condition has an item in an odd row that is a struct but does not have 'expression' and 'fields' keys", function(){
				var service          = _getService();
				var validationResult = _newValidationResult();
				var badlyFormedCondition = SerializeJson( [
					{ "expression":"event.attendance", "fields":{} },
					"or",
					[
						{ "expression":"has.membership", "fields":{} },
						"and",
						{ "expression":"user.visits", "fields":{} },
						"and",
						[
							{ "test":true },
							"and",
							{ "expression":"found.egg", "fields":{} }
						]
					],
					"and",
					{ "expression":"is.legend", "fields":{} }
				] );

				service.validateCondition(
					  condition        = badlyFormedCondition
					, validationResult = validationResult
					, context          = "any"
				);

				expect( validationResult.getGeneralMessage() ).toBe( "The passed condition was malformed and could not be read" );
			} );

			it( "should return false when passed condition has an invalid expression item", function(){
				var service              = _getService();
				var validationResult     = _newValidationResult();
				var context              = CreateUUId();
				var badlyFormedCondition = [
					{ "expression":"event.attendance", "fields":{ test=CreateUUId() } }
				];

				mockExpressionService.$( "isExpressionValid" ).$args(
					  expressionId     = badlyFormedCondition[1].expression
					, fields           = badlyFormedCondition[1].fields
					, context          = context
					, validationResult = validationResult
				).$results( false );

				expect( service.validateCondition(
					  condition        = SerializeJson( badlyFormedCondition )
					, validationResult = validationResult
					, context          = context
				) ).toBeFalse();
			} );
		} );

		describe( "evaluateCondition()", function(){
			it( "should return true when it contains a single expression that evaluates to true for the given payload", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( true );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeTrue();
			} );

			it( "should supplement the payload with a payload retrieved automaticaly from the context", function(){
				var service      = _getService();
				var payload      = { blah=CreateUUId() };
				var extraPayload = { test=CreateUUId() };
				var finalPayload = { blah=payload.blah, test=extraPayload.test };
				var context      = CreateUUId();
				var conditionId  = CreateUUId();
				var condition    = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockContextService.$( "getContextPayload" ).$args( context=context, args=payload ).$results( extraPayload );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = finalPayload
				).$results( true );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeTrue();
			} );

			it( "should return false when it contains a single expression that evaluates to false for the given payload", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( false );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeFalse();
			} );

			it( "should return false when the condition does not exist", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();

				service.$( "getCondition" ).$args( conditionId ).$results( {} );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeFalse();
			} );

			it( "should return true when the condition contains two 'true' evaluating expressions separated by an 'and'", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"and",{
					  expression = "another.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( true );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3].expression
					, configuredFields = condition[3].fields
					, context          = context
					, payload          = payload
				).$results( true );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeTrue();
			} );

			it( "should return false when the condition contains one 'true' evaluating expression followed by a 'false' evaluating expression and separated by an 'and'", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"and",{
					  expression = "another.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( true );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3].expression
					, configuredFields = condition[3].fields
					, context          = context
					, payload          = payload
				).$results( false );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeFalse();
			} );

			it( "should return false when the condition contains one 'false' evaluating expression followed by a 'true' evaluating expression and separated by an 'and'", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"and",{
					  expression = "another.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( false );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3].expression
					, configuredFields = condition[3].fields
					, context          = context
					, payload          = payload
				).$results( true );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeFalse();
			} );

			it( "should not evaluate the second expression when the condition contains one 'false' evaluating expression followed by a 'true' evaluating expression and separated by an 'and'", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"and",{
					  expression = "another.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( false );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3].expression
					, configuredFields = condition[3].fields
					, context          = context
					, payload          = payload
				).$results( true );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeFalse();

				expect( mockExpressionService.$callLog().evaluateExpression.len() ).toBe( 1 );
			} );

			it( "should return true when the condition contains one 'false' evaluating expression followed by a 'true' evaluating expression and separated by an 'or'", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"or",{
					  expression = "another.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( false );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3].expression
					, configuredFields = condition[3].fields
					, context          = context
					, payload          = payload
				).$results( true );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeTrue();
			} );

			it( "should return true when the condition contains one 'true' evaluating expression followed by a 'false' evaluating expression and separated by an 'or'", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"or",{
					  expression = "another.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( true );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3].expression
					, configuredFields = condition[3].fields
					, context          = context
					, payload          = payload
				).$results( false );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeTrue();
			} );

			it( "should not evaluate the second expression when the condition contains one 'true' evaluating expression followed by a 'false' evaluating expression and separated by an 'or'", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"or",{
					  expression = "another.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( true );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3].expression
					, configuredFields = condition[3].fields
					, context          = context
					, payload          = payload
				).$results( false );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeTrue();

				expect( mockExpressionService.$callLog().evaluateExpression.len() ).toBe( 1 );
			} );

			it( "should return true when the condition contains two 'true' evaluating expressions separated by an 'or'", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"or",{
					  expression = "another.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( true );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3].expression
					, configuredFields = condition[3].fields
					, context          = context
					, payload          = payload
				).$results( true );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeTrue();
			} );

			it( "should return false when the condition contains two 'false' evaluating expressions separated by an 'or'", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"or",{
					  expression = "another.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( false );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3].expression
					, configuredFields = condition[3].fields
					, context          = context
					, payload          = payload
				).$results( false );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeFalse();
			} );

			it( "should return true when the condition contains a complex and nested structure of expressions that follow logical boolean rules", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"and",[{
						  expression = "another.expression"
						, fields     = { test=CreateUUId(), _is=true }
					},"or",[{
							  expression = "another.expression"
							, fields     = { test=CreateUUId(), _is=true }
							},"and",{
							  expression = "another.expression"
							, fields     = { test=CreateUUId(), _is=true } }
							]
					]
				];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( true );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3][1].expression
					, configuredFields = condition[3][1].fields
					, context          = context
					, payload          = payload
				).$results( false );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3][3][1].expression
					, configuredFields = condition[3][3][1].fields
					, context          = context
					, payload          = payload
				).$results( true );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3][3][3].expression
					, configuredFields = condition[3][3][3].fields
					, context          = context
					, payload          = payload
				).$results( true );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeTrue();
			} );

			it( "should return false when the condition contains a complex and nested structure of expressions that follow logical boolean rules that would evaluate false", function(){
				var service     = _getService();
				var payload     = { blah=CreateUUId() };
				var context     = CreateUUId();
				var conditionId = CreateUUId();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"and",[{
						  expression = "another.expression"
						, fields     = { test=CreateUUId(), _is=true }
					},"or",[{
							  expression = "another.expression"
							, fields     = { test=CreateUUId(), _is=true }
							},"and",{
							  expression = "another.expression"
							, fields     = { test=CreateUUId(), _is=true }
							},"and",{
							  expression = "boom.expression"
							, fields     = { test=CreateUUId(), _is=true }
							} ]
					]
				];

				service.$( "getCondition" ).$args( conditionId ).$results( { expressions=condition } );

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( true );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3][1].expression
					, configuredFields = condition[3][1].fields
					, context          = context
					, payload          = payload
				).$results( false );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3][3][1].expression
					, configuredFields = condition[3][3][1].fields
					, context          = context
					, payload          = payload
				).$results( true );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3][3][3].expression
					, configuredFields = condition[3][3][3].fields
					, context          = context
					, payload          = payload
				).$results( true );
				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[3][3][5].expression
					, configuredFields = condition[3][3][5].fields
					, context          = context
					, payload          = payload
				).$results( false );

				expect( service.evaluateCondition(
					  conditionId = conditionId
					, context     = context
					, payload     = payload
				) ).toBeFalse();
			} );
		} );

		describe( "listObjectsFilterableByCondition()", function(){
			it( "should return an array of objects that are commonly applicable amongst all the expressions in the given condition", function(){
				var service = _getService();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"and",{
					  expression = "another.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"and",{
					  expression = "final.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				mockExpressionService.$( "getFilterObjectsForExpression" ).$args( "test.expression"    ).$results( [ "object_a", "object_d", "object_b" ] );
				mockExpressionService.$( "getFilterObjectsForExpression" ).$args( "another.expression" ).$results( [ "object_a", "object_c", "object_d" ] );
				mockExpressionService.$( "getFilterObjectsForExpression" ).$args( "final.expression"   ).$results( [ "object_a", "object_b", "object_c", "object_d" ] );

				expect( service.listObjectsFilterableByCondition( condition ) ).toBe( [ "object_a", "object_d" ] );
			} );

			it( "should return an empty array when no objects are commonly shared amongst all the expressions", function(){
				var service = _getService();
				var condition   = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"and",{
					  expression = "another.expression"
					, fields     = { test=CreateUUId(), _is=true }
				},
				"and",{
					  expression = "final.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				mockExpressionService.$( "getFilterObjectsForExpression" ).$args( "test.expression"    ).$results( [ "object_a", "object_d", "object_b" ] );
				mockExpressionService.$( "getFilterObjectsForExpression" ).$args( "another.expression" ).$results( [ "object_e" ] );
				mockExpressionService.$( "getFilterObjectsForExpression" ).$args( "final.expression"   ).$results( [ "object_a", "object_b", "object_c", "object_d" ] );

				expect( service.listObjectsFilterableByCondition( condition ) ).toBe( [] );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService() {
		variables.mockColdbox = createStub();
		variables.mockExpressionService = createEmptyMock( "preside.system.services.rulesEngine.RulesEngineExpressionService" );
		variables.mockContextService = createEmptyMock( "preside.system.services.rulesEngine.RulesEngineContextService" );
		variables.mockConditionDao = createStub();

		var service = createMock( object=new preside.system.services.rulesEngine.RulesEngineConditionService(
			  expressionService = mockExpressionService
			, contextService    = mockContextService
		) );

		service.$( "$getColdbox", mockColdbox );
		service.$( "$getPresideObject" ).$args( "rules_engine_condition" ).$results( mockConditionDao );
		mockExpressionService.$( "isExpressionValid", true );
		mockContextService.$( "getContextPayload", {} );

		return service;
	}

	private any function _newValidationResult() {
		return new preside.system.services.validation.ValidationResult();
	}
}