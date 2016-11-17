component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "generateExpressionsForProperty()", function(){
			it( "should return a configured '(property) is/is not empty' expression for a string property that is nullable", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				var propertyDef  = { name="myprop", type="string", required=false };
				var baseI18n     = "whatever:";
				var expectedExpr = {
					  id                    = "presideobject_textPropertyIsNull"
					, contexts              = [ "presideobject_" & objectName ]
					, fields                = { _is={ fieldtype="boolean", variety="isIsNot" } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
					, expressionHandlerArgs = { objectName=objectName, propertyName=propertyDef.name }
					, filterHandlerArgs     = { objectName=objectName, propertyName=propertyDef.name }
					, i18nLabelArgs         = [ basei18n & "title.singular", basei18n & "field.#propertyDef.name#.title" ]
					, i18nTextArgs          = [ basei18n & "title.singular", basei18n & "field.#propertyDef.name#.title" ]
				};

				mockPresideObjectService.$( "getResourceBundleUriRoot" ).$args( objectName ).$results( basei18n );

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
				var baseI18n     = "whatever:";
				var expectedExpr = {
					  id                    = "presideobject_textPropertyIsNull"
					, contexts              = [ "presideobject_" & objectName ]
					, fields                = { _is={ fieldtype="boolean", variety="isIsNot" } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
					, expressionHandlerArgs = { objectName=objectName, propertyName=propertyDef.name }
					, filterHandlerArgs     = { objectName=objectName, propertyName=propertyDef.name }
					, i18nLabelArgs         = [ basei18n & "title.singular", basei18n & "field.#propertyDef.name#.title" ]
					, i18nTextArgs          = [ basei18n & "title.singular", basei18n & "field.#propertyDef.name#.title" ]
				};

				mockPresideObjectService.$( "getResourceBundleUriRoot" ).$args( objectName ).$results( basei18n );

				var expressions = builder.generateExpressionsForProperty(
					  objectName         = objectName
					, propertyDefinition = propertyDef
				);

				expect( expressions.find( expectedExpr ) ).toBe( 0 );

			} );
		} );
	}

// PRIVATE
	private any function _getBuilder() {
		var builder = createMock( object=new preside.system.services.rulesEngine.RulesEngineAutoPresideObjectExpressionGenerator() );

		mockPresideObjectService = createEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );

		builder.$( "$getPresideObjectService", mockPresideObjectService );

		return builder;
	}
}