/**
 * Service that provides logic for automatically generating rules
 * engine expressions from the preside object library.
 *
 * @autodoc        true
 * @singleton      true
 * @presideService true
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @rulesEngineExpressionService.inject rulesEngineExpressionService
	 * @rulesEngineContextService.inject    rulesEngineContextService
	 *
	 */
	public any function init(
		  required any rulesEngineExpressionService
		, required any rulesEngineContextService
	) {
		_setRulesEngineExpressionService( arguments.rulesEngineExpressionService );
		_setRulesEngineContextService( arguments.rulesEngineContextService );

		return this;
	}


// PUBLIC API
	public void function generateAndRegisterAutoExpressions() {
		var objects = $getPresideObjectService().listObjects();

		for( var objectName in objects ) {
			var properties = $getPresideObjectService().getObjectProperties( objectName );
			for( var propName in properties ) {
				if ( !propName.startsWith( "_" ) ) {
					var expressions = generateExpressionsForProperty( objectName, properties[ propName ] );
					for( var expression in expressions ) {
						_getRulesEngineExpressionService().addExpression( argumentCollection=expression );
					}
					if ( expressions.len() ) {
						_getRulesEngineContextService().addContext( id="presideobject_" & objectName, object=objectName );
					}
				}
			}

		}
	}

	/**
	 * Generates all the expressions for a given property (does the hard work)
	 *
	 */
	public array function generateExpressionsForProperty(
		  required string objectName
		, required struct propertyDefinition
	) {
		var isRequired   = IsBoolean( propertyDefinition.required ?: "" ) && propertyDefinition.required;
		var propType     = propertyDefinition.type ?: "string";
		var relationship = propertyDefinition.relationship ?: "";
		var expressions  = [];

		if ( !isRequired && !( [ "many-to-many", "one-to-many" ] ).findNoCase( relationship ) ) {
			switch( propType ) {
				case "string":
				case "numeric":
					expressions.append( _createIsEmptyExpression( objectName, propertyDefinition.name ) );
				break;
				default:
					expressions.append( _createIsSetExpression( objectName, propertyDefinition.name ) );
			}
		}

		if ( !relationship contains "many" ) {
			switch( propType ) {
				case "string":
					expressions.append( _createStringMatchExpression( objectName, propertyDefinition.name ) );
				break;
				case "boolean":
					expressions.append( _createBooleanIsTrueExpression( objectName, propertyDefinition.name ) );
				break;
				case "date":
					expressions.append( _createDateInRangeExpression( objectName, propertyDefinition.name ) );
				break;
				case "numeric":
					expressions.append( _createNumericComparisonExpression( objectName, propertyDefinition.name ) );
				break;
			}
		}

		switch( relationship ) {
			case "many-to-one":
				expressions.append( _createManyToOneMatchExpression( objectName, propertyDefinition ) );
			break;
			case "many-to-many":
				expressions.append( _createManyToManyMatchExpression( objectName, propertyDefinition ) );
				expressions.append( _createManyToManyCountExpression( objectName, propertyDefinition ) );
			break;
			case "one-to-many":
				expressions.append( _createOneToManyMatchExpression( objectName, propertyDefinition ) );
				expressions.append( _createOneToManyCountExpression( objectName, propertyDefinition ) );
			break;
		}

		return expressions;
	}

// PRIVATE HELPERS
	private struct function _createIsEmptyExpression( required string objectName, required string propertyName ) {
		var expression  = _getCommonExpressionDefinition( objectName, propertyName );

		expression.append( {
			  id                = "presideobject_propertyIsEmpty_#arguments.propertyName#"
			, fields            = { _is={ fieldType="boolean", variety="isIsNot", default=true, required=false } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.PropertyIsNull.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getText"
		} );

		expression.expressionHandlerArgs.variety = "isEmpty";
		expression.filterHandlerArgs.variety     = "isEmpty";
		expression.labelHandlerArgs.variety      = "isEmpty";
		expression.textHandlerArgs.variety       = "isEmpty";

		return expression;
	}

	private struct function _createStringMatchExpression( required string objectName, required string propertyName ) {
		var expression  = _getCommonExpressionDefinition( objectName, propertyName );

		expression.append( {
			  id                = "presideobject_stringmatches_#arguments.propertyName#"
			, fields            = { _stringOperator={ fieldType="operator", variety="string", required=false, default="contains" }, value={ fieldType="text", required=false, default="" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.getText"
		} );

		return expression;
	}

	private struct function _createIsSetExpression( required string objectName, required string propertyName ) {
		var expression  = _getCommonExpressionDefinition( objectName, propertyName );

		expression.append( {
			  id                = "presideobject_propertyIsSet_#arguments.propertyName#"
			, fields            = { _is={ fieldType="boolean", variety="isIsNot", default=true, required=false } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.PropertyIsNull.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.PropertyIsNull.getText"
		} );

		expression.expressionHandlerArgs.variety = "isSet";
		expression.filterHandlerArgs.variety     = "isSet";
		expression.labelHandlerArgs.variety      = "isSet";
		expression.textHandlerArgs.variety       = "isSet";

		return expression;
	}

	private struct function _createBooleanIsTrueExpression( required string objectName, required string propertyName ) {
		var expression  = _getCommonExpressionDefinition( objectName, propertyName );

		expression.append( {
			  id                = "presideobject_booleanistrue_#arguments.propertyName#"
			, fields            = { _is={ fieldType="boolean", variety="isIsNot", required=false, default=true } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.BooleanPropertyIsTrue.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.BooleanPropertyIsTrue.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.BooleanPropertyIsTrue.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.BooleanPropertyIsTrue.getText"
		} );

		return expression;
	}

	private struct function _createDateInRangeExpression( required string objectName, required string propertyName ) {
		var expression  = _getCommonExpressionDefinition( objectName, propertyName );

		expression.append( {
			  id                = "presideobject_dateinrange_#arguments.propertyName#"
			, fields            = { _time={ fieldtype="timePeriod", type="alltime", required=false, default="" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.getText"
		} );

		return expression;
	}

	private struct function _createNumericComparisonExpression( required string objectName, required string propertyName ) {
		var expression  = _getCommonExpressionDefinition( objectName, propertyName );

		expression.append( {
			  id                = "presideobject_numbercompares_#arguments.propertyName#"
			, fields            = { _numericOperator={ fieldtype="operator", variety="numeric", required=false, default="eq" }, value={ fieldtype="number", required=false, default=0 } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.NumericPropertyCompares.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.NumericPropertyCompares.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.NumericPropertyCompares.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.NumericPropertyCompares.getText"
		} );

		return expression;
	}

	private struct function _createManyToOneMatchExpression( required string objectName, required struct propertyDefinition ) {
		var expression  = _getCommonExpressionDefinition( objectName, propertyDefinition.name );

		expression.append( {
			  id                = "presideobject_manytoonematch_#arguments.propertyDefinition.name#"
			, fields            = { _is={ fieldType="boolean", variety="isIsNot", default=true, required=false }, value={ fieldType="object", object=propertyDefinition.relatedTo, multiple=true, required=true, default="", defaultLabel="rules.dynamicExpressions:manyToOneMatch.value.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.ManyToOneMatch.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.ManyToOneMatch.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.ManyToOneMatch.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.ManyToOneMatch.getText"
		} );
		expression.expressionHandlerArgs.relatedTo = propertyDefinition.relatedTo;
		expression.filterHandlerArgs.relatedTo     = propertyDefinition.relatedTo;
		expression.labelHandlerArgs.relatedTo      = propertyDefinition.relatedTo;
		expression.textHandlerArgs.relatedTo       = propertyDefinition.relatedTo;

		return expression;
	}

	private struct function _createManyToManyMatchExpression( required string objectName, required struct propertyDefinition ) {
		var expression  = _getCommonExpressionDefinition( objectName, propertyDefinition.name );

		expression.append( {
			  id                = "presideobject_manytomanymatch_#arguments.propertyDefinition.name#"
			, fields            = { _possesses={ fieldType="boolean", variety="hasDoesNotHave", default=true, required=false }, value={ fieldType="object", object=propertyDefinition.relatedTo, multiple=true, required=true, default="", defaultLabel="rules.dynamicExpressions:manyToManyMatch.value.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.ManyToManyMatch.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.ManyToManyMatch.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.ManyToManyMatch.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.ManyToManyMatch.getText"
		} );
		expression.expressionHandlerArgs.relatedTo = propertyDefinition.relatedTo;
		expression.filterHandlerArgs.relatedTo     = propertyDefinition.relatedTo;
		expression.labelHandlerArgs.relatedTo      = propertyDefinition.relatedTo;
		expression.textHandlerArgs.relatedTo       = propertyDefinition.relatedTo;

		return expression;
	}

	private struct function _createOneToManyMatchExpression( required string objectName, required struct propertyDefinition ) {
		var expression  = _getCommonExpressionDefinition( objectName, propertyDefinition.name );

		expression.append( {
			  id                = "presideobject_onetomanymatch_#arguments.propertyDefinition.name#"
			, fields            = { _is={ fieldType="boolean", variety="isIsNot", default=true, required=false }, value={ fieldType="object", object=propertyDefinition.relatedTo, multiple=true, required=true, default="", defaultLabel="rules.dynamicExpressions:oneToManyMatch.value.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.OneToManyMatch.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.OneToManyMatch.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.OneToManyMatch.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.OneToManyMatch.getText"
		} );
		expression.expressionHandlerArgs.relatedTo       = propertyDefinition.relatedTo;
		expression.filterHandlerArgs.relatedTo           = propertyDefinition.relatedTo;
		expression.labelHandlerArgs.relatedTo            = propertyDefinition.relatedTo;
		expression.textHandlerArgs.relatedTo             = propertyDefinition.relatedTo;
		expression.expressionHandlerArgs.relationshipKey = ( propertyDefinition.relationshipKey ?: arguments.objectName );
		expression.filterHandlerArgs.relationshipKey     = ( propertyDefinition.relationshipKey ?: arguments.objectName );
		expression.labelHandlerArgs.relationshipKey      = ( propertyDefinition.relationshipKey ?: arguments.objectName );
		expression.textHandlerArgs.relationshipKey       = ( propertyDefinition.relationshipKey ?: arguments.objectName );

		return expression;
	}

	private struct function _createManyToManyCountExpression( required string objectName, required struct propertyDefinition ) {
		var expression  = _getCommonExpressionDefinition( objectName, propertyDefinition.name );

		expression.append( {
			  id                = "presideobject_manytomanycount_#arguments.propertyDefinition.name#"
			, fields            = { _numericOperator={ fieldtype="operator", variety="numeric", required=false, default="eq" }, value={ fieldType="number", required=false, default=0 } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.ManyToManyCount.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.ManyToManyCount.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.ManyToManyCount.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.ManyToManyCount.getText"
		} );
		expression.expressionHandlerArgs.relatedTo = propertyDefinition.relatedTo;
		expression.filterHandlerArgs.relatedTo     = propertyDefinition.relatedTo;
		expression.labelHandlerArgs.relatedTo      = propertyDefinition.relatedTo;
		expression.textHandlerArgs.relatedTo       = propertyDefinition.relatedTo;

		return expression;
	}

	private struct function _createOneToManyCountExpression( required string objectName, required struct propertyDefinition ) {
		var expression  = _getCommonExpressionDefinition( objectName, propertyDefinition.name );

		expression.append( {
			  id                = "presideobject_onetomanycount_#arguments.propertyDefinition.name#"
			, fields            = { _numericOperator={ fieldtype="operator", variety="numeric", required=false, default="eq" }, value={ fieldType="number", required=false, default=0 } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.OneToManyCount.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.OneToManyCount.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.OneToManyCount.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.OneToManyCount.getText"
		} );
		expression.expressionHandlerArgs.relatedTo       = propertyDefinition.relatedTo;
		expression.filterHandlerArgs.relatedTo           = propertyDefinition.relatedTo;
		expression.labelHandlerArgs.relatedTo            = propertyDefinition.relatedTo;
		expression.textHandlerArgs.relatedTo             = propertyDefinition.relatedTo;
		expression.expressionHandlerArgs.relationshipKey = ( propertyDefinition.relationshipKey ?: arguments.objectName );
		expression.filterHandlerArgs.relationshipKey     = ( propertyDefinition.relationshipKey ?: arguments.objectName );
		expression.labelHandlerArgs.relationshipKey      = ( propertyDefinition.relationshipKey ?: arguments.objectName );
		expression.textHandlerArgs.relationshipKey       = ( propertyDefinition.relationshipKey ?: arguments.objectName );

		return expression;
	}


	private struct function _getCommonExpressionDefinition( required string objectName, required string propertyName ){
		return {
			  contexts              = [ "presideobject_" & objectName ]
			, filterObjects         = [ objectName ]
			, expressionHandlerArgs = { propertyName=propertyName }
			, filterHandlerArgs     = { propertyName=propertyName }
			, labelHandlerArgs      = { propertyName=propertyName }
			, textHandlerArgs       = { propertyName=propertyName }
		};
	}





// GETTERS AND SETTERS
	private any function _getRulesEngineExpressionService() {
		return _rulesEngineExpressionService;
	}
	private void function _setRulesEngineExpressionService( required any rulesEngineExpressionService ) {
		_rulesEngineExpressionService = arguments.rulesEngineExpressionService;
	}

	private any function _getRulesEngineContextService() {
		return _rulesEngineContextService;
	}
	private void function _setRulesEngineContextService( required any rulesEngineContextService ) {
		_rulesEngineContextService = arguments.rulesEngineContextService;
	}
}