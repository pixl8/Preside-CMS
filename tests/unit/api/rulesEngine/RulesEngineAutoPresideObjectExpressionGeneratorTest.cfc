component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "generateExpressionsForProperty()", function(){
			it( "should return a configured '(property) is/is not empty' expression for a string property that is nullable", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				var propertyDef  = { name="myprop", type="string", required=false };
				var expectedExpr = {
					  id                    = "presideobject_propertyIsEmpty_#objectName#.#propertyDef.name#"
					, contexts              = _mockContexts( objectName )
					, category              = objectName
					, fields                = { _is={ fieldtype="boolean", variety="isIsNot", default=true, required=false } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.PropertyIsNull.prepareFilters"
					, labelHandler          = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getLabel"
					, textHandler           = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, objectName=objectName, variety="isEmpty" }
					, filterHandlerArgs     = { propertyName=propertyDef.name, objectName=objectName, variety="isEmpty" }
					, labelHandlerArgs      = { propertyName=propertyDef.name, objectName=objectName, variety="isEmpty" }
					, textHandlerArgs       = { propertyName=propertyDef.name, objectName=objectName, variety="isEmpty" }
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
					  id                    = "presideobject_propertyIsEmpty_#objectName#.#propertyDef.name#"
					, contexts              = _mockContexts( objectName )
					, category              = objectName
					, fields                = { _is={ fieldtype="boolean", variety="isIsNot", default=true, required=false } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.PropertyIsNull.prepareFilters"
					, labelHandler          = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getLabel"
					, textHandler           = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, objectName=objectName, variety="isEmpty" }
					, filterHandlerArgs     = { propertyName=propertyDef.name, objectName=objectName, variety="isEmpty" }
					, labelHandlerArgs      = { propertyName=propertyDef.name, objectName=objectName, variety="isEmpty" }
					, textHandlerArgs       = { propertyName=propertyDef.name, objectName=objectName, variety="isEmpty" }
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
					  id                    = "presideobject_propertyIsEmpty_#objectName#.#propertyDef.name#"
					, contexts              = _mockContexts( objectName )
					, category              = objectName
					, fields                = { _is={ fieldtype="boolean", variety="isIsNot", default=true, required=false } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.PropertyIsNull.prepareFilters"
					, labelHandler          = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getLabel"
					, textHandler           = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, objectName=objectName, variety="isEmpty" }
					, filterHandlerArgs     = { propertyName=propertyDef.name, objectName=objectName, variety="isEmpty" }
					, labelHandlerArgs      = { propertyName=propertyDef.name, objectName=objectName, variety="isEmpty" }
					, textHandlerArgs       = { propertyName=propertyDef.name, objectName=objectName, variety="isEmpty" }
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
					  id                    = "presideobject_propertyIsSet_#objectName#.#propertyDef.name#"
					, contexts              = _mockContexts( objectName )
					, category              = objectName
					, fields                = { _is={ fieldtype="boolean", variety="isIsNot", default=true, required=false } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.PropertyIsNull.prepareFilters"
					, labelHandler          = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getLabel"
					, textHandler           = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, objectName=objectName, variety="isSet" }
					, filterHandlerArgs     = { propertyName=propertyDef.name, objectName=objectName, variety="isSet" }
					, labelHandlerArgs      = { propertyName=propertyDef.name, objectName=objectName, variety="isSet" }
					, textHandlerArgs       = { propertyName=propertyDef.name, objectName=objectName, variety="isSet" }
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
					  id                    = "presideobject_stringmatches_#objectName#.#propertyDef.name#"
					, contexts              = _mockContexts( objectName )
					, category              = objectName
					, fields                = { _stringOperator={ fieldtype="operator", variety="string", required=false, default="eq" }, value={ fieldtype="text", required=false, default="" } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.prepareFilters"
					, labelHandler          = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.getLabel"
					, textHandler           = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, objectName=objectName }
					, filterHandlerArgs     = { propertyName=propertyDef.name, objectName=objectName }
					, labelHandlerArgs      = { propertyName=propertyDef.name, objectName=objectName }
					, textHandlerArgs       = { propertyName=propertyDef.name, objectName=objectName }
				};

				var expressions = builder.generateExpressionsForProperty(
					  objectName         = objectName
					, propertyDefinition = propertyDef
				);

				expect( expressions.find( expectedExpr ) > 0 ).toBe( true );

			} );

			it( "should return a configured 'is true' expression for a boolean property", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				var propertyDef  = { name="myprop", type="boolean", required=true };
				var expectedExpr = {
					  id                    = "presideobject_booleanistrue_#objectName#.#propertyDef.name#"
					, contexts              = _mockContexts( objectName )
					, category              = objectName
					, fields                = { _is={ fieldtype="boolean", variety="isIsNot", required=false, default=true } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.BooleanPropertyIsTrue.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.BooleanPropertyIsTrue.prepareFilters"
					, labelHandler          = "rules.dynamic.presideObjectExpressions.BooleanPropertyIsTrue.getLabel"
					, textHandler           = "rules.dynamic.presideObjectExpressions.BooleanPropertyIsTrue.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, objectName=objectName }
					, filterHandlerArgs     = { propertyName=propertyDef.name, objectName=objectName }
					, labelHandlerArgs      = { propertyName=propertyDef.name, objectName=objectName }
					, textHandlerArgs       = { propertyName=propertyDef.name, objectName=objectName }
				};

				var expressions = builder.generateExpressionsForProperty(
					  objectName         = objectName
					, propertyDefinition = propertyDef
				);

				expect( expressions.find( expectedExpr ) > 0 ).toBe( true );

			} );

			it( "should return a configured 'date range' expression for a date property", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				var propertyDef  = { name="myprop", type="date", required=true };
				var expectedExpr = {
					  id                    = "presideobject_dateinrange_#objectName#.#propertyDef.name#"
					, contexts              = _mockContexts( objectName )
					, category              = objectName
					, fields                = { _time={ fieldtype="timeperiod", type="alltime", required=false, default="", isDate=false } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.prepareFilters"
					, labelHandler          = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.getLabel"
					, textHandler           = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, objectName=objectName }
					, filterHandlerArgs     = { propertyName=propertyDef.name, objectName=objectName }
					, labelHandlerArgs      = { propertyName=propertyDef.name, objectName=objectName }
					, textHandlerArgs       = { propertyName=propertyDef.name, objectName=objectName }
				};

				mockPresideObjectService.$( "getObjectPropertyAttribute" ).$args( objectname, propertyDef.name, "dbtype" ).$results( "datetime" );

				var expressions = builder.generateExpressionsForProperty(
					  objectName         = objectName
					, propertyDefinition = propertyDef
				);
				expect( expressions[1] ).toBe( expectedExpr );
				expect( expressions.findNoCase( expectedExpr ) > 0 ).toBe( true );
			} );

			it( "should return a configured 'numeric comparison' expression for a numeric property", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				var propertyDef  = { name="myprop", type="numeric", required=true };
				var expectedExpr = {
					  id                    = "presideobject_numbercompares_#objectName#.#propertyDef.name#"
					, contexts              = _mockContexts( objectName )
					, category              = objectName
					, fields                = { _numericOperator={ fieldtype="operator", variety="numeric", required=false, default="eq" }, value={ fieldtype="number", required=false, default=0 } }
					, filterObjects         = [ objectName ]
					, expressionHandler     = "rules.dynamic.presideObjectExpressions.NumericPropertyCompares.evaluateExpression"
					, filterHandler         = "rules.dynamic.presideObjectExpressions.NumericPropertyCompares.prepareFilters"
					, labelHandler          = "rules.dynamic.presideObjectExpressions.NumericPropertyCompares.getLabel"
					, textHandler           = "rules.dynamic.presideObjectExpressions.NumericPropertyCompares.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, objectName=objectName }
					, filterHandlerArgs     = { propertyName=propertyDef.name, objectName=objectName }
					, labelHandlerArgs      = { propertyName=propertyDef.name, objectName=objectName }
					, textHandlerArgs       = { propertyName=propertyDef.name, objectName=objectName }
				};

				var expressions = builder.generateExpressionsForProperty(
					  objectName         = objectName
					, propertyDefinition = propertyDef
				);
				expect( expressions.findNoCase( expectedExpr ) > 0 ).toBe( true );
			} );

			it( "should return a configured 'outdatedtranslation' expression for the _translations property of a multilingual object", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				var propertyDef  = { name="_translations", relationship="one-to-many", relatedTo="_translation_some_object", required=false };
				var expectedExpr = {
					  id                    = "presideobject_outdatedtranslation_#objectName#.#propertyDef.name#"
					, contexts              = _mockContexts( objectName )
					, category              = objectName
					, fields                = { _possesses={ fieldType="boolean", variety="hasDoesNotHave", required=false, default=true }, value={ fieldType="object", object="multilingual_language", multiple=true, required=true, default="", defaultLabel="rules.dynamicExpressions:outdatedTranslation.value.default.label" } }
					, filterObjects         = [ objectName ]
					, expressionHandler = "rules.dynamic.presideObjectExpressions.OutdatedTranslation.evaluateExpression"
					, filterHandler     = "rules.dynamic.presideObjectExpressions.OutdatedTranslation.prepareFilters"
					, labelHandler      = "rules.dynamic.presideObjectExpressions.OutdatedTranslation.getLabel"
					, textHandler       = "rules.dynamic.presideObjectExpressions.OutdatedTranslation.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, objectName=objectName, relatedTo=propertyDef.relatedTo, relationshipKey=objectName }
					, filterHandlerArgs     = { propertyName=propertyDef.name, objectName=objectName, relatedTo=propertyDef.relatedTo, relationshipKey=objectName }
					, labelHandlerArgs      = { propertyName=propertyDef.name, objectName=objectName, relatedTo=propertyDef.relatedTo, relationshipKey=objectName }
					, textHandlerArgs       = { propertyName=propertyDef.name, objectName=objectName, relatedTo=propertyDef.relatedTo, relationshipKey=objectName }
				};
				expectedExpr.fields.value.append( propertyDef, false );

				var expressions = builder.generateExpressionsForProperty(
					  objectName         = objectName
					, propertyDefinition = propertyDef
				);
				expect( expressions.findNoCase( expectedExpr ) > 0 ).toBe( true );
			} );

			it( "should return a configured 'translationexists' expression for the _translations property of a multilingual object", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				var propertyDef  = { name="_translations", relationship="one-to-many", relatedTo="_translation_some_object", required=false };
				var expectedExpr = {
					  id                    = "presideobject_translationexists_#objectName#.#propertyDef.name#"
					, contexts              = _mockContexts( objectName )
					, category              = objectName
					, fields                = { _possesses={ fieldType="boolean", variety="hasDoesNotHave", required=false, default=true }, value={ fieldType="object", object="multilingual_language", multiple=true, required=true, default="", defaultLabel="rules.dynamicExpressions:TranslationExists.value.default.label" }, savedFilter={ fieldType="filter", object=propertyDef.relatedTo, multiple=false, quickadd=true, quickedit=true, required=false, default="", defaultLabel="rules.dynamicExpressions:TranslationExists.savedFilter.default.label" } }
					, filterObjects         = [ objectName ]
					, expressionHandler = "rules.dynamic.presideObjectExpressions.TranslationExists.evaluateExpression"
					, filterHandler     = "rules.dynamic.presideObjectExpressions.TranslationExists.prepareFilters"
					, labelHandler      = "rules.dynamic.presideObjectExpressions.TranslationExists.getLabel"
					, textHandler       = "rules.dynamic.presideObjectExpressions.TranslationExists.getText"
					, expressionHandlerArgs = { propertyName=propertyDef.name, objectName=objectName, relatedTo=propertyDef.relatedTo, relationshipKey=objectName }
					, filterHandlerArgs     = { propertyName=propertyDef.name, objectName=objectName, relatedTo=propertyDef.relatedTo, relationshipKey=objectName }
					, labelHandlerArgs      = { propertyName=propertyDef.name, objectName=objectName, relatedTo=propertyDef.relatedTo, relationshipKey=objectName }
					, textHandlerArgs       = { propertyName=propertyDef.name, objectName=objectName, relatedTo=propertyDef.relatedTo, relationshipKey=objectName }
				};
				expectedExpr.fields.value.append( propertyDef, false );
				var expressions = builder.generateExpressionsForProperty(
					  objectName         = objectName
					, propertyDefinition = propertyDef
				);

				expect( expressions.findNoCase( expectedExpr ) > 0 ).toBe( true );
			} );

			it( "should NOT return 'onetomanymatch' and 'onetomanycount' expressions for the _translations property of a multilingual object", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				_mockContexts( objectName );
				var propertyDef  = { name="_translations", relationship="one-to-many", relatedTo="_translation_some_object", required=false, excludeAutoExpressions="OneToManyMatch,OneToManyCount" };

				var expressions = builder.generateExpressionsForProperty(
					  objectName         = objectName
					, propertyDefinition = propertyDef
				);

				var exprIds = arrayMap( expressions, function( expr ) {
   					return expr.id;
				} );

				expect( exprIds.find( "presideobject_onetomanycount_#objectName#.#propertyDef.name#" ) > 0 ).toBe( false );
				expect( exprIds.find( "presideobject_onetomanymatch_#objectName#.#propertyDef.name#" ) > 0 ).toBe( false );

			} );
		} );

		describe( "getAutoExpressionsForObject()", function(){
			it( "should return a configured '{object} matches saved filter' expression", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				var contexts     = _mockContexts( objectName );

				mockPresideObjectService.$( "getLabelField" ).$args( objectname ).$results( "label" );
				mockPresideObjectService.$( "getObjectProperties" ).$args( objectname ).$results( {} );
				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectname, "autoGenerateFilterExpressionsFor" ).$results( "" );

				var expectedExpr = {
					id = "presideobject_recordmatchesfilter_#objectName#"
				};

				var expressions = builder.getAutoExpressionsForObject(
					objectName = objectName
				);

				expect( arraySome( expressions, function( expr ) {
					return "presideobject_recordmatchesfilter_#objectName#" == expr.id ?: "";
				} ) ).toBe( 1 );

			} ) ;
			it( "should return a configured '{object} matches specific records' expression if the object has a label field", function(){
				var builder      = _getBuilder();
				var objectName   = "some_object";
				var contexts     = _mockContexts( objectName );

				mockPresideObjectService.$( "getLabelField" ).$args( objectname ).$results( "label" );
				mockPresideObjectService.$( "getObjectProperties" ).$args( objectname ).$results( {} );
				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectname, "autoGenerateFilterExpressionsFor" ).$results( "" );

				var expectedExpr = {
					id = "presideobject_recordmatchesid_#objectName#"
				};

				var expressions = builder.getAutoExpressionsForObject(
					objectName = objectName
				);

				expect( arraySome( expressions, function( expr ) {
					return "presideobject_recordmatchesid_#objectName#" == expr.id ?: "";
				} ) ).toBe( 1 );
			} );

			it( "should NOT generate a '{object} matches specific records' expression if the object has no label field", function(){
				var builder      = _getBuilder();
				var objectName   = "some_other_object";
				var contexts     = _mockContexts( objectName );

				mockPresideObjectService.$( "getLabelField" ).$args( objectname ).$results( "" );
				mockPresideObjectService.$( "getObjectProperties" ).$args( objectname ).$results( {} );
				mockPresideObjectService.$( "getObjectAttribute" ).$args( objectname, "autoGenerateFilterExpressionsFor" ).$results( "" );

				var expectedExpr = {
					id = "presideobject_recordmatchesid_#objectName#"
				};

				var expressions = builder.getAutoExpressionsForObject(
					objectName = objectName
				);

				expect( arraySome( expressions, function( expr ) {
					return "presideobject_recordmatchesid_#objectName#" == expr.id ?: "";
				} ) ).toBe( 0 );
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
		builder.$( "_getBooleanVariety", "hasDoesNotHave" );
		builder.$( "$isFeatureEnabled", true );

		return builder;
	}

	private array function _mockContexts( required string objectName ) {
		var contexts = [ CreateUUId(), CreateUUId() ];

		mockContextService.$( "getObjectContexts" ).$args( objectname ).$results( contexts );

		return contexts;
	}
}