component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getExpression()", function(){
			it( "should return a structure representing the expression including translated label and expression text", function(){
				var service      = _getService();
				var expressionId = "userGroup.event_booking";
				var expected     = Duplicate( mockExpressions[ expressionId ] );

				expected.label = CreateUUId();
				expected.text  = CreateUUId();

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

	}


// PRIVATE HELPERS
	private any function _getService( struct expressions=_getDefaultTestExpressions() ) {
		variables.mockReaderService = CreateEmptyMock( "preside.system.services.rulesEngine.RulesEngineExpressionReaderService" );
		variables.mockDirectories   = [ "/dir1/expressions", "/dir2/expressions", "/dir3/expressions" ];
		variables.mockExpressions   = arguments.expressions;

		mockReaderService.$( "getExpressionsFromDirectories" ).$args( mockDirectories ).$results( mockExpressions );

		var service = new preside.system.services.rulesEngine.RulesEngineExpressionService(
			  expressionReaderService = mockReaderService
			, expressionDirectories   = mockDirectories
		);

		return createMock( object=service );
	}

	private struct function _getDefaultTestExpressions() {
		return {
			  "userGroup.user"          = { fields={}, contexts=[ "user" ] }
			, "userGroup.event_booking" = { fields={}, contexts=[ "event_booking" ] }
		};
	}

}