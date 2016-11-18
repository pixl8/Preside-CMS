component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "generateExpressionsForProperty()", function(){
			it( "should return a configured '(property) is/is not empty' expression for a string property that is nullable", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				var propertyDef  = { name="myprop", type="string", required=false };
				var expectedExpr = {
					  id                    = "presideobject_propertyIsEmpty_#propertyDef.name#"
					, contexts              = [ "presideobject_" & objectName ]
					, fields                = { _is={ fieldtype="boolean", variety="isIsNot", default=true, required=false } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.PropertyIsNull.prepareFilters"
					, labelHandler          = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getLabel"
					, textHandler           = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, variety="isEmpty" }
					, filterHandlerArgs     = { propertyName=propertyDef.name, variety="isEmpty" }
					, labelHandlerArgs      = { propertyName=propertyDef.name, variety="isEmpty" }
					, textHandlerArgs       = { propertyName=propertyDef.name, variety="isEmpty" }
				};

				var expressions = builder.generateExpressionsForProperty(
					  objectName         = objectName
					, propertyDefinition = propertyDef
				);

				expect( expressions.find( expectedExpr ) > 0 ).toBe( true );

			} );

			it( "should not return a configured '(property) is/is not empty' expression for a string property that is not nullable (required)", function(){
				var builder      = _getBuilder();
				var objectName   = "my_obj";
				var propertyDef  = { name="myprop", type="string", required=true };
				var expectedExpr = {
					  id                    = "presideobject_propertyIsEmpty_#propertyDef.name#"
					, contexts              = [ "presideobject_" & objectName ]
					, fields                = { _is={ fieldtype="boolean", variety="isIsNot", default=true, required=false } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.PropertyIsNull.prepareFilters"
					, labelHandler          = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getLabel"
					, textHandler           = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, variety="isEmpty" }
					, filterHandlerArgs     = { propertyName=propertyDef.name, variety="isEmpty" }
					, labelHandlerArgs      = { propertyName=propertyDef.name, variety="isEmpty" }
					, textHandlerArgs       = { propertyName=propertyDef.name, variety="isEmpty" }
				};

				var expressions = builder.generateExpressionsForProperty(
					  objectName         = objectName
					, propertyDefinition = propertyDef
				);

				expect( expressions.find( expectedExpr ) ).toBe( 0 );

			} );

			it( "should return a configured '(property) is/is not empty' expression for a numeric property that is nullable", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				var propertyDef  = { name="myprop", type="numeric", required=false };
				var expectedExpr = {
					  id                    = "presideobject_propertyIsEmpty_#propertyDef.name#"
					, contexts              = [ "presideobject_" & objectName ]
					, fields                = { _is={ fieldtype="boolean", variety="isIsNot", default=true, required=false } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.PropertyIsNull.prepareFilters"
					, labelHandler          = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getLabel"
					, textHandler           = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, variety="isEmpty" }
					, filterHandlerArgs     = { propertyName=propertyDef.name, variety="isEmpty" }
					, labelHandlerArgs      = { propertyName=propertyDef.name, variety="isEmpty" }
					, textHandlerArgs       = { propertyName=propertyDef.name, variety="isEmpty" }
				};

				var expressions = builder.generateExpressionsForProperty(
					  objectName         = objectName
					, propertyDefinition = propertyDef
				);

				expect( expressions.find( expectedExpr ) > 0 ).toBe( true );

			} );

			it( "should return a configured '(property) is/is not set' expression for a boolean property that is nullable", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				var propertyDef  = { name="myprop", type="boolean", required=false };
				var expectedExpr = {
					  id                    = "presideobject_propertyIsSet_#propertyDef.name#"
					, contexts              = [ "presideobject_" & objectName ]
					, fields                = { _is={ fieldtype="boolean", variety="isIsNot", default=true, required=false } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.PropertyIsNull.prepareFilters"
					, labelHandler          = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getLabel"
					, textHandler           = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, variety="isSet" }
					, filterHandlerArgs     = { propertyName=propertyDef.name, variety="isSet" }
					, labelHandlerArgs      = { propertyName=propertyDef.name, variety="isSet" }
					, textHandlerArgs       = { propertyName=propertyDef.name, variety="isSet" }
				};

				var expressions = builder.generateExpressionsForProperty(
					  objectName         = objectName
					, propertyDefinition = propertyDef
				);

				expect( expressions.find( expectedExpr ) > 0 ).toBe( true );

			} );

			it( "should return a configured 'string matches' expression for a string property", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				var propertyDef  = { name="myprop", type="string", required=true };
				var expectedExpr = {
					  id                    = "presideobject_stringmatches_#propertyDef.name#"
					, contexts              = [ "presideobject_" & objectName ]
					, fields                = { _stringOperator={ fieldtype="operator", variety="string", required=false, default="contains" }, value={ fieldtype="text", required=false, default="" } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.prepareFilters"
					, labelHandler          = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.getLabel"
					, textHandler           = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name }
					, filterHandlerArgs     = { propertyName=propertyDef.name }
					, labelHandlerArgs      = { propertyName=propertyDef.name }
					, textHandlerArgs       = { propertyName=propertyDef.name }
				};

				var expressions = builder.generateExpressionsForProperty(
					  objectName         = objectName
					, propertyDefinition = propertyDef
				);

				expect( expressions.find( expectedExpr ) > 0 ).toBe( true );

			} );
		} );
	}

// PRIVATE
	private any function _getBuilder() {
		mockPresideObjectService = createEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		mockExpressionsService   = createEmptyMock( "preside.system.services.rulesEngine.RulesEngineExpressionService" );
		mockContextService       = createEmptyMock( "preside.system.services.rulesEngine.RulesEngineContextService" );


		var builder = createMock( object=new preside.system.services.rulesEngine.RulesEngineAutoPresideObjectExpressionGenerator(
			  rulesEngineExpressionService = mockExpressionsService
			, rulesEngineContextService    = mockContextService
		) );

		builder.$( "$getPresideObjectService", mockPresideObjectService );

		return builder;
	}
}