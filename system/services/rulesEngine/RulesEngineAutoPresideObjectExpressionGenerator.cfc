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
	 * @rulesEngineContextService.inject rulesEngineContextService
	 *
	 */
	public any function init( required any rulesEngineContextService ) {
		_setRulesEngineContextService( rulesEngineContextService );
		return this;
	}


// PUBLIC API
	public array function getAutoExpressionsForObject( required string objectName ) {
		var properties                      = $getPresideObjectService().getObjectProperties( arguments.objectName );
		var relatedObjectsForAutoGeneration = $getPresideObjectService().getObjectAttribute( arguments.objectName, "autoGenerateFilterExpressionsFor" ).trim();
		var expressions                     = [];

		for( var propName in properties ) {
			expressions.append( generateExpressionsForProperty( arguments.objectName, properties[ propName ] ), true );
		}
		for( var relatedObjectPath in relatedObjectsForAutoGeneration.listToArray() ) {
			expressions.append( _createExpressionsForRelatedObjectProperties( arguments.objectName, relatedObjectPath.trim() ), true );
		}

		return expressions;
	}

	/**
	 * Generates all the expressions for a given property (does the hard work)
	 *
	 */
	public array function generateExpressionsForProperty(
		  required string objectName
		, required struct propertyDefinition
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	) {
		if ( IsBoolean( propertyDefinition.autofilter ?: "" ) && !propertyDefinition.autofilter ) {
			return [];
		}
		if ( ( propertyDefinition.formula ?: "" ).len() ) {
			return [];
		}

		var isRequired   = IsBoolean( propertyDefinition.required ?: "" ) && propertyDefinition.required;
		var propType     = propertyDefinition.type ?: "string";
		var relationship = propertyDefinition.relationship ?: "";
		var relatedTo    = propertyDefinition.relatedTo ?: "";
		var expressions  = [];

		if ( !isRequired && !( [ "many-to-many", "one-to-many" ] ).findNoCase( relationship ) ) {
			switch( propType ) {
				case "string":
				case "numeric":
					expressions.append( _createIsEmptyExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
				break;
				default:
					expressions.append( _createIsSetExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
			}
		}

		if ( !relationship contains "many" ) {
			switch( propType ) {
				case "string":
					if ( !Len( Trim( propertyDefinition.enum ?: "" ) ) ) {
						expressions.append( _createStringMatchExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
					}
				break;
				case "boolean":
					expressions.append( _createBooleanIsTrueExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
				break;
				case "date":
					expressions.append( _createDateInRangeExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
				break;
				case "numeric":
					expressions.append( _createNumericComparisonExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
				break;
			}
		}

		switch( relationship ) {
			case "many-to-one":
				expressions.append( _createManyToOneMatchExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				expressions.append( _createManyToOneFilterExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );

				if ( relatedTo == "security_user" ) {
					expressions.append( _createManyToOneMatchesLoggedInAdminUserExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				}
				if ( relatedTo == "website_user" ) {
					expressions.append( _createManyToOneMatchesLoggedInWebUserExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				}
				if ( !arguments.parentObjectName.len() ) {
					if ( IsBoolean( propertyDefinition.autoGenerateFilterExpressions ?: "" ) && propertyDefinition.autoGenerateFilterExpressions ) {
						expressions.append( _createExpressionsForRelatedObjectProperties( objectName, propertyDefinition.name ), true );
					} else {
						var uniqueIndexes = ListToArray( propertyDefinition.uniqueIndexes ?: "" );
						for( var ux in uniqueIndexes ) {
							if ( ListLen( ux, "|" ) == 1 ) {
								expressions.append( _createExpressionsForRelatedObjectProperties( objectName, propertyDefinition.name ), true );
								break;
							}
						}
					}
				}
			break;
			case "many-to-many":
				expressions.append( _createManyToManyMatchExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				expressions.append( _createManyToManyCountExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				expressions.append( _createManyToManyHasExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
			break;
			case "one-to-many":
				expressions.append( _createOneToManyMatchExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				expressions.append( _createOneToManyCountExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				expressions.append( _createOneToManyHasExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
			break;
		}

		if ( Len( Trim( propertyDefinition.enum ?: "" ) ) ) {
			expressions.append( _createEnumMatchesExpression( objectName, propertyDefinition.name, propertyDefinition.enum, parentObjectName, parentPropertyName ) );
		}


		return expressions;
	}

// PRIVATE HELPERS
	private struct function _createIsEmptyExpression( required string objectName, required string propertyName, required string parentObjectName, required string parentPropertyName ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments );

		expression.append( {
			  id                = "presideobject_propertyIsEmpty_#arguments.parentObjectname##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyName#"
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

	private struct function _createStringMatchExpression( required string objectName, required string propertyName, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments );

		expression.append( {
			  id                = "presideobject_stringmatches_#arguments.parentObjectname##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyName#"
			, fields            = { _stringOperator={ fieldType="operator", variety="string", required=false, default="contains" }, value={ fieldType="text", required=false, default="" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.getText"
		} );

		return expression;
	}

	private struct function _createEnumMatchesExpression( required string objectName, required string propertyName, required string enum, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments );

		expression.append( {
			  id                = "presideobject_enumMatches_#arguments.parentObjectname##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyName#"
			, fields            = { _is={ fieldType="boolean", variety="isIsNot", required=false, default=true }, enumValue={ fieldType="enum", enum=arguments.enum, required=false, default="", defaultLabel="rules.dynamicExpressions:enumPropertyMatches.enumValue.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.EnumPropertyMatches.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.EnumPropertyMatches.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.EnumPropertyMatches.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.EnumPropertyMatches.getText"
		} );

		return expression;
	}

	private struct function _createIsSetExpression( required string objectName, required string propertyName, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments );

		expression.append( {
			  id                = "presideobject_propertyIsSet_#arguments.parentObjectname##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyName#"
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

	private struct function _createBooleanIsTrueExpression( required string objectName, required string propertyName, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments );

		expression.append( {
			  id                = "presideobject_booleanistrue_#arguments.parentObjectname##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyName#"
			, fields            = { _is={ fieldType="boolean", variety="isIsNot", required=false, default=true } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.BooleanPropertyIsTrue.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.BooleanPropertyIsTrue.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.BooleanPropertyIsTrue.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.BooleanPropertyIsTrue.getText"
		} );

		return expression;
	}

	private struct function _createDateInRangeExpression( required string objectName, required string propertyName, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments );

		expression.append( {
			  id                = "presideobject_dateinrange_#arguments.parentObjectname##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyName#"
			, fields            = { _time={ fieldtype="timePeriod", type="alltime", required=false, default="" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.getText"
		} );

		return expression;
	}

	private struct function _createNumericComparisonExpression( required string objectName, required string propertyName, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments );

		expression.append( {
			  id                = "presideobject_numbercompares_#arguments.parentObjectname##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyName#"
			, fields            = { _numericOperator={ fieldtype="operator", variety="numeric", required=false, default="eq" }, value={ fieldtype="number", required=false, default=0 } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.NumericPropertyCompares.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.NumericPropertyCompares.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.NumericPropertyCompares.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.NumericPropertyCompares.getText"
		} );

		return expression;
	}

	private struct function _createManyToOneMatchExpression( required string objectName, required struct propertyDefinition, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName=propertyDefinition.name );

		expression.append( {
			  id                = "presideobject_manytoonematch_#arguments.parentObjectName##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyDefinition.name#"
			, fields            = { _is={ fieldType="boolean", variety="isIsNot", default=true, required=false }, value={ fieldType="object", object=propertyDefinition.relatedTo, multiple=true, required=true, default="", defaultLabel="rules.dynamicExpressions:manyToOneMatch.value.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.ManyToOneMatch.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.ManyToOneMatch.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.ManyToOneMatch.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.ManyToOneMatch.getText"
		} );

		expression.fields.value.append( arguments.propertyDefinition, false );

		expression.expressionHandlerArgs.relatedTo = propertyDefinition.relatedTo;
		expression.filterHandlerArgs.relatedTo     = propertyDefinition.relatedTo;
		expression.labelHandlerArgs.relatedTo      = propertyDefinition.relatedTo;
		expression.textHandlerArgs.relatedTo       = propertyDefinition.relatedTo;

		return expression;
	}

	private struct function _createManyToOneMatchesLoggedInAdminUserExpression( required string objectName, required struct propertyDefinition, required string parentObjectName, required string parentPropertyName ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName=propertyDefinition.name );

		expression.append( {
			  id                = "presideobject_manytoonematch_loggedinadminuser_#arguments.parentObjectName##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyDefinition.name#"
			, fields            = { _is={ fieldType="boolean", variety="isIsNot", default=true, required=false } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.ManyToOneMatchLoggedInAdminUser.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.ManyToOneMatchLoggedInAdminUser.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.ManyToOneMatchLoggedInAdminUser.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.ManyToOneMatchLoggedInAdminUser.getText"
		} );

		return expression;
	}

	private struct function _createManyToOneMatchesLoggedInWebUserExpression( required string objectName, required struct propertyDefinition, required string parentObjectName, required string parentPropertyName ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName=propertyDefinition.name );

		expression.append( {
			  id                = "presideobject_manytoonematch_loggedinadminuser_#arguments.parentObjectName##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyDefinition.name#"
			, fields            = { _is={ fieldType="boolean", variety="isIsNot", default=true, required=false } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.ManyToOneMatchLoggedInWebUser.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.ManyToOneMatchLoggedInWebUser.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.ManyToOneMatchLoggedInWebUser.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.ManyToOneMatchLoggedInWebUser.getText"
		} );

		return expression;
	}

	private struct function _createManyToOneFilterExpression( required string objectName, required struct propertyDefinition, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName=propertyDefinition.name );

		expression.append( {
			  id                = "presideobject_manytoonefilter_#arguments.parentObjectName##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyDefinition.name#"
			, fields            = { value={ fieldType="filter", object=propertyDefinition.relatedTo, multiple=false, quickadd=true, quickedit=true, required=true, default="", defaultLabel="rules.dynamicExpressions:manyToOneFilter.value.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.ManyToOneFilter.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.ManyToOneFilter.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.ManyToOneFilter.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.ManyToOneFilter.getText"
		} );

		expression.fields.value.append( arguments.propertyDefinition, false );

		expression.expressionHandlerArgs.relatedTo = propertyDefinition.relatedTo;
		expression.filterHandlerArgs.relatedTo     = propertyDefinition.relatedTo;
		expression.labelHandlerArgs.relatedTo      = propertyDefinition.relatedTo;
		expression.textHandlerArgs.relatedTo       = propertyDefinition.relatedTo;

		return expression;
	}

	private struct function _createManyToManyMatchExpression( required string objectName, required struct propertyDefinition, required string parentObjectName, required string parentPropertyName  ) {
		var expression       = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName=propertyDefinition.name );
		var possessesVariety = _getBooleanVariety( arguments.objectName, arguments.propertyDefinition.name, "possesses" );

		expression.append( {
			  id                = "presideobject_manytomanymatch_#arguments.parentObjectName##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyDefinition.name#"
			, fields            = { _possesses={ fieldType="boolean", variety=possessesVariety, default=true, required=false }, value={ fieldType="object", object=propertyDefinition.relatedTo, multiple=true, required=false, default="", defaultLabel="rules.dynamicExpressions:manyToManyMatch.value.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.ManyToManyMatch.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.ManyToManyMatch.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.ManyToManyMatch.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.ManyToManyMatch.getText"
		} );

		expression.fields.value.append( arguments.propertyDefinition, false );

		expression.expressionHandlerArgs.relatedTo            = propertyDefinition.relatedTo;
		expression.filterHandlerArgs.relatedTo                = propertyDefinition.relatedTo;
		expression.labelHandlerArgs.relatedTo                 = propertyDefinition.relatedTo;
		expression.textHandlerArgs.relatedTo                  = propertyDefinition.relatedTo;

		expression.expressionHandlerArgs.relatedVia           = propertyDefinition.relatedVia;
		expression.expressionHandlerArgs.relatedViaSourceFk   = propertyDefinition.relatedViaSourceFk;
		expression.expressionHandlerArgs.relatedViaTargetFk   = propertyDefinition.relatedViaTargetFk;
		expression.expressionHandlerArgs.relationshipIsSource = propertyDefinition.relationshipIsSource;
		expression.filterHandlerArgs.relatedVia               = propertyDefinition.relatedVia;
		expression.filterHandlerArgs.relatedViaSourceFk       = propertyDefinition.relatedViaSourceFk;
		expression.filterHandlerArgs.relatedViaTargetFk       = propertyDefinition.relatedViaTargetFk;
		expression.filterHandlerArgs.relationshipIsSource     = propertyDefinition.relationshipIsSource;

		return expression;
	}

	private struct function _createOneToManyMatchExpression( required string objectName, required struct propertyDefinition, required string parentObjectName, required string parentPropertyName  ) {
		var expression       = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName=propertyDefinition.name );
		var possessesVariety = _getBooleanVariety( arguments.objectName, arguments.propertyDefinition.name, "possesses" );

		expression.append( {
			  id                = "presideobject_onetomanymatch_#arguments.parentObjectName##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyDefinition.name#"
			, fields            = { _is={ fieldType="boolean", variety=possessesVariety, default=true, required=false }, value={ fieldType="object", object=propertyDefinition.relatedTo, multiple=true, required=true, default="", defaultLabel="rules.dynamicExpressions:oneToManyMatch.value.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.OneToManyMatch.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.OneToManyMatch.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.OneToManyMatch.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.OneToManyMatch.getText"
		} );

		expression.fields.value.append( arguments.propertyDefinition, false );

		expression.fields.value.append( arguments.propertyDefinition, false );
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

	private struct function _createManyToManyCountExpression( required string objectName, required struct propertyDefinition, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName=propertyDefinition.name );

		expression.append( {
			  id                = "presideobject_manytomanycount_#arguments.parentObjectName##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyDefinition.name#"
			, fields            = { _numericOperator={ fieldtype="operator", variety="numeric", required=false, default="eq" }, value={ fieldType="number", required=false, default=0 }, savedFilter={ fieldType="filter", object=propertyDefinition.relatedTo, multiple=false, quickadd=true, quickedit=true, required=true, default="", defaultLabel="rules.dynamicExpressions:manyToManyCount.savedFilter.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.ManyToManyCount.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.ManyToManyCount.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.ManyToManyCount.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.ManyToManyCount.getText"
		} );

		expression.fields.value.append( arguments.propertyDefinition, false );

		expression.expressionHandlerArgs.relatedTo = propertyDefinition.relatedTo;
		expression.filterHandlerArgs.relatedTo     = propertyDefinition.relatedTo;
		expression.labelHandlerArgs.relatedTo      = propertyDefinition.relatedTo;
		expression.textHandlerArgs.relatedTo       = propertyDefinition.relatedTo;

		return expression;
	}

	private struct function _createManyToManyHasExpression( required string objectName, required struct propertyDefinition, required string parentObjectName, required string parentPropertyName  ) {
		var expression       = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName=propertyDefinition.name );
		var possessesVariety = _getBooleanVariety( arguments.objectName, arguments.propertyDefinition.name, "possesses" );

		expression.append( {
			  id                = "presideobject_manytomanyhas_#arguments.parentObjectName##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyDefinition.name#"
			, fields            = { _possesses={ fieldType="boolean", variety=possessesVariety, required=false, default=true }, value={ fieldType="number", required=false, default=0 }, savedFilter={ fieldType="filter", object=propertyDefinition.relatedTo, multiple=false, quickadd=true, quickedit=true, required=true, default="", defaultLabel="rules.dynamicExpressions:manyToManyCount.savedFilter.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.ManyToManyHas.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.ManyToManyHas.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.ManyToManyHas.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.ManyToManyHas.getText"
		} );

		expression.fields.value.append( arguments.propertyDefinition, false );

		expression.expressionHandlerArgs.relatedTo = propertyDefinition.relatedTo;
		expression.filterHandlerArgs.relatedTo     = propertyDefinition.relatedTo;
		expression.labelHandlerArgs.relatedTo      = propertyDefinition.relatedTo;
		expression.textHandlerArgs.relatedTo       = propertyDefinition.relatedTo;

		return expression;
	}

	private struct function _createOneToManyCountExpression( required string objectName, required struct propertyDefinition, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName=propertyDefinition.name );

		expression.append( {
			  id                = "presideobject_onetomanycount_#arguments.parentObjectName##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyDefinition.name#"
			, fields            = { _numericOperator={ fieldtype="operator", variety="numeric", required=false, default="eq" }, value={ fieldType="number", required=false, default=0 }, savedFilter={ fieldType="filter", object=propertyDefinition.relatedTo, multiple=false, quickadd=true, quickedit=true, required=true, default="", defaultLabel="rules.dynamicExpressions:oneToManyCount.savedFilter.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.OneToManyCount.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.OneToManyCount.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.OneToManyCount.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.OneToManyCount.getText"
		} );

		expression.fields.value.append( arguments.propertyDefinition, false );

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

	private struct function _createOneToManyHasExpression( required string objectName, required struct propertyDefinition, required string parentObjectName, required string parentPropertyName  ) {
		var expression       = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName=propertyDefinition.name );
		var possessesVariety = _getBooleanVariety( arguments.objectName, arguments.propertyDefinition.name, "possesses" );

		expression.append( {
			  id                = "presideobject_onetomanyhas_#arguments.parentObjectName##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyDefinition.name#"
			, fields            = { _is={ fieldType="boolean", variety=possessesVariety, required=false, default=true }, value={ fieldType="number", required=false, default=0 }, savedFilter={ fieldType="filter", object=propertyDefinition.relatedTo, multiple=false, quickadd=true, quickedit=true, required=true, default="", defaultLabel="rules.dynamicExpressions:oneToManyHas.savedFilter.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.OneToManyHas.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.OneToManyHas.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.OneToManyHas.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.OneToManyHas.getText"
		} );

		expression.fields.value.append( arguments.propertyDefinition, false );

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


	private struct function _getCommonExpressionDefinition(
		  required string objectName
		, required string propertyName
		, required string parentObjectName
		, required string parentPropertyName
	){
		var sourceObject = parentObjectName.len() ? parentObjectName : objectName;
		var commonArgs   = {
			  propertyName = propertyName
			, objectName   = objectName
		};

		if ( parentPropertyName.len() ) {
			commonArgs.parentPropertyName = parentPropertyName;
			commonArgs.parentObjectName   = parentObjectName;
		}

		return {
			  contexts              = _getRulesEngineContextService().getObjectContexts( sourceObject )
			, filterObjects         = [ sourceObject ]
			, expressionHandlerArgs = commonArgs
			, filterHandlerArgs     = commonArgs
			, labelHandlerArgs      = commonArgs
			, textHandlerArgs       = commonArgs
			, category              = objectName
		};
	}

	private array function _createExpressionsForRelatedObjectProperties(
		  required string objectName
		, required string propertyName
	) {
		var poService          = $getPresideObjectService();
		var propertyChain      = arguments.propertyName.listToArray( "." );
		var currentObjectName  = arguments.objectName;
		var parentPropertyName = arguments.propertyName.listChangeDelims( "$", "." );
		var expressions        = [];

		for( var propName in propertyChain ) {
			var prop = poService.getObjectProperty( currentObjectName, propName );

			currentObjectName = prop.relatedto ?: "";
		}

		if ( currentObjectName.len() ) {
			var properties = $getPresideObjectService().getObjectProperties( currentObjectName );

			for( var propName in properties ) {
				expressions.append( generateExpressionsForProperty(
					  objectName         = currentObjectName
					, propertyDefinition = properties[ propName ]
					, parentObjectName   = objectName
					, parentPropertyName = parentPropertyName
				), true );
			}
		}

		return expressions;
	}

	private string function _getBooleanVariety( required string objectname, required string propertyName, required string variety ) {
		var defaultVariety = "isIsNot";
		var overrideUri    = $getPresideObjectService().getResourceBundleUriRoot( arguments.objectName ) & "field.#arguments.propertyName#.#arguments.variety#";
		var truthy         = $translateResource( uri=overrideUri & ".truthy", defaultvalue="" );
		var falsey         = $translateResource( uri=overrideUri & ".falsey", defaultvalue="" );

		if ( truthy.len() && falsey.len() ) {
			return overrideUri;
		}

		switch( arguments.variety ) {
			case "possesses":
				defaultVariety = "hasDoesNotHave";
			break;
		}

		return defaultVariety;
	}



// GETTERS AND SETTERS
	private any function _getRulesEngineContextService() {
		return _rulesEngineContextService;
	}
	private void function _setRulesEngineContextService( required any rulesEngineContextService ) {
		_rulesEngineContextService = arguments.rulesEngineContextService;
	}
}