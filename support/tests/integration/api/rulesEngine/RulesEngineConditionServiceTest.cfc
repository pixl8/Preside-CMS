component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
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
				var service   = _getService();
				var payload   = { blah=CreateUUId() };
				var context   = CreateUUId();
				var condition = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( true );

				expect( service.evaluateCondition(
					  condition = SerializeJson( condition )
					, context   = context
					, payload   = payload
				) ).toBeTrue();
			} );

			it( "should return false when it contains a single expression that evaluates to false for the given payload", function(){
				var service   = _getService();
				var payload   = { blah=CreateUUId() };
				var context   = CreateUUId();
				var condition = [{
					  expression = "test.expression"
					, fields     = { test=CreateUUId(), _is=true }
				}];

				mockExpressionService.$( "evaluateExpression" ).$args(
					  expressionId     = condition[1].expression
					, configuredFields = condition[1].fields
					, context          = context
					, payload          = payload
				).$results( false );

				expect( service.evaluateCondition(
					  condition = SerializeJson( condition )
					, context   = context
					, payload   = payload
				) ).toBeFalse();
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService() {
		variables.mockColdbox = createStub();
		variables.mockExpressionService = createEmptyMock( "preside.system.services.rulesEngine.RulesEngineExpressionService" );

		var service = createMock( object=new preside.system.services.rulesEngine.RulesEngineConditionService(
			expressionService = mockExpressionService
		) );

		service.$( "$getColdbox", mockColdbox );
		mockExpressionService.$( "isExpressionValid", true );

		return service;
	}

	private any function _newValidationResult() {
		return new preside.system.services.validation.ValidationResult();
	}
}