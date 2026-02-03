/**
 * Service that provides logic for automatically generating rules
 * engine expressions from the preside object library.
 *
 * @autodoc        true
 * @singleton      true
 * @presideService true
 * @feature        rulesEngine
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

		ArrayAppend( expressions, _createRecordMatchesFilterExpression( arguments.objectName ) );
		if ( len( $getPresideObjectService().getLabelField( arguments.objectName ) ) ) {
			ArrayAppend( expressions, _createRecordMatchesIdExpression( arguments.objectName ) );
		}

		for( var propName in properties ) {
			expressions.append( generateExpressionsForProperty( arguments.objectName, properties[ propName ] ), true );
		}
		for( var relatedObjectPath in ListToArray( relatedObjectsForAutoGeneration ) ) {
			ArrayAppend( expressions, _createExpressionsForRelatedObjectProperties( arguments.objectName, Trim( relatedObjectPath ) ), true );
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

		if ( ( propertyDefinition.relationship ?: "" ) == "select-data-view" ) {
			return [];
		}

		var isRequired   = IsBoolean( propertyDefinition.required ?: "" ) && propertyDefinition.required;
		var propType     = propertyDefinition.type ?: "string";
		var relationship = propertyDefinition.relationship ?: "";
		var relatedTo    = propertyDefinition.relatedTo ?: "";
		var expressions  = [];
		var isFormula    = Len( Trim( propertyDefinition.formula ?: "" ) );
		var excludedKeys = listToArray( propertyDefinition.excludeAutoExpressions ?: "" );

		if ( isFormula && !Len( $getPresideObjectService().getIdField( arguments.objectName ) ) ) {
			return [];
		}

		if ( !isRequired && !( [ "many-to-many", "one-to-many" ] ).findNoCase( relationship ) && !isFormula ) {
			switch( propType ) {
				case "string":
				case "numeric":
					if ( !arrayContainsNoCase( excludedKeys, "PropertyIsNull" ) ) {
						arrayAppend( expressions, _createIsEmptyExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
					}
				break;
				default:
					if ( !arrayContainsNoCase( excludedKeys, "PropertyIsNull" ) ) {
						arrayAppend( expressions, _createIsSetExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
					}
			}
		}

		if ( !relationship contains "many" ) {
			switch( propType ) {
				case "string":
					if ( isFormula ) {
						if ( !arrayContainsNoCase( excludedKeys, "TextFormulaPropertyMatches" ) ) {
							arrayAppend( expressions, _createStringFormulaMatchExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
						}
					} else if ( !arrayContainsNoCase( excludedKeys, "TextPropertyMatches" ) ) {
						arrayAppend( expressions, _createStringMatchExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
					}
				break;
				case "boolean":
					if ( isFormula ) {
						if ( !arrayContainsNoCase( excludedKeys, "BooleanFormulaPropertyIsTrue" ) ) {
							arrayAppend( expressions, _createBooleanFormulaIsTrueExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
						}
					} else if ( !arrayContainsNoCase( excludedKeys, "BooleanPropertyIsTrue" ) ) {
						arrayAppend( expressions, _createBooleanIsTrueExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
					}
				break;
				case "date":
					if ( isFormula ) {
						if ( !arrayContainsNoCase( excludedKeys, "DateFormulaPropertyInRange" ) ) {
							arrayAppend( expressions, _createDateFormulaInRangeExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
						}
					} else if ( !arrayContainsNoCase( excludedKeys, "DatePropertyInRange" ) ) {
						arrayAppend( expressions, _createDateInRangeExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
					}
				break;
				case "numeric":
					if ( isFormula ) {
						if ( !arrayContainsNoCase( excludedKeys, "NumericFormulaPropertyCompares" ) ) {
							arrayAppend( expressions, _createNumericFormulaComparisonExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
						}
					} else if ( !arrayContainsNoCase( excludedKeys, "NumericPropertyCompares" ) ) {
						arrayAppend( expressions, _createNumericComparisonExpression( objectName, propertyDefinition.name, parentObjectName, parentPropertyName ) );
					}
				break;
			}
		}

		switch( relationship ) {
			case "many-to-one":
				if ( !arrayContainsNoCase( excludedKeys, "ManyToOneMatch" ) ) {
					arrayAppend( expressions, _createManyToOneMatchExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				}

				if ( !arrayContainsNoCase( excludedKeys, "ManyToOneFilter" ) ) {
					arrayAppend( expressions, _createManyToOneFilterExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				}

				if ( relatedTo == "security_user" && !arrayContainsNoCase( excludedKeys, "ManyToOneMatchLoggedInAdminUser" ) && $isFeatureEnabled( "admin" ) ) {
					arrayAppend( expressions, _createManyToOneMatchesLoggedInAdminUserExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				}
				if ( relatedTo == "website_user" && !arrayContainsNoCase( excludedKeys, "ManyToOneMatchLoggedInWebUser" ) && $isFeatureEnabled( "websiteUsers" )) {
					arrayAppend( expressions, _createManyToOneMatchesLoggedInWebUserExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
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
				if ( !arrayContainsNoCase( excludedKeys, "ManyToManyMatch" ) ) {
					arrayAppend( expressions, _createManyToManyMatchExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				}
				if ( !arrayContainsNoCase( excludedKeys, "ManyToManyCount" ) ) {
					arrayAppend( expressions, _createManyToManyCountExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				}
				if ( !arrayContainsNoCase( excludedKeys, "ManyToManyHas" ) ) {
					arrayAppend( expressions, _createManyToManyHasExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				}
			break;
			case "one-to-many":
				if ( !arrayContainsNoCase( excludedKeys, "OneToManyMatch" ) ) {
					arrayAppend( expressions, _createOneToManyMatchExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				}
				if ( !arrayContainsNoCase( excludedKeys, "OneToManyCount" ) ) {
					arrayAppend( expressions, _createOneToManyCountExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				}
				if ( !arrayContainsNoCase( excludedKeys, "OneToManyHas" ) ) {
					arrayAppend( expressions, _createOneToManyHasExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				}
				if ( reFind( "^\_translation\_", relatedTo ) && $isFeatureEnabled( "multilingual" ) ) {
					arrayAppend( expressions, _createOutdatedTranslationExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
					arrayAppend( expressions, _createTranslationExistsExpression( objectName, propertyDefinition, parentObjectName, parentPropertyName ) );
				}
			break;
		}

		if ( Len( Trim( propertyDefinition.enum ?: "" ) ) ) {
			if ( isFormula ) {
				if ( !arrayContainsNoCase( excludedKeys, "EnumFormulaPropertyMatches" ) ) {
					arrayAppend( expressions, _createEnumFormulaMatchesExpression( objectName, propertyDefinition.name, propertyDefinition.enum, parentObjectName, parentPropertyName ) );
				}
			} else if ( !arrayContainsNoCase( excludedKeys, "EnumPropertyMatches" ) ) {
				arrayAppend( expressions, _createEnumMatchesExpression( objectName, propertyDefinition.name, propertyDefinition.enum, parentObjectName, parentPropertyName ) );
			}
		}


		return expressions;
	}

// PRIVATE HELPERS
	private struct function _createRecordMatchesFilterExpression( required string objectName ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName="", parentObjectName="", parentPropertyName="" );

		expression.append( {
			  id                = "presideobject_recordmatchesfilter_#arguments.objectName#"
			, expressionHandler = "rules.dynamic.presideObjectExpressions.RecordMatchesFilters.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.RecordMatchesFilters.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.RecordMatchesFilters.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.RecordMatchesFilters.getText"
			, fields            = {
				  value = { fieldType="filter", object=arguments.objectName, multiple=true, quickadd=true, quickedit=true, required=true, default="", defaultLabel="rules.dynamicExpressions:recordMatchesFilters.value.default.label" }
				, _does = { fieldType="boolean", variety="doesDoesNot", default=true, required=false }
			  }
		} );

		return expression;
	}

	private struct function _createRecordMatchesIdExpression( required string objectName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName="", parentObjectName="", parentPropertyName="" );

		expression.append( {
			  id                = "presideobject_recordmatchesid_#arguments.objectName#"
			, fields            = { _is={ fieldType="boolean", variety="isIsNot", default=true, required=false }, value={ fieldType="object", object=objectName, multiple=true, required=true, default="", defaultLabel="rules.dynamicExpressions:recordMatchesId.value.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.RecordMatchesId.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.RecordMatchesId.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.RecordMatchesId.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.RecordMatchesId.getText"
		} );

		return expression;
	}

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
			, fields            = { _stringOperator={ fieldType="operator", variety="string", required=false, default="eq" }, value={ fieldType="text", required=false, default="" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.TextPropertyMatches.getText"
		} );

		return expression;
	}

	private struct function _createStringFormulaMatchExpression( required string objectName, required string propertyName, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments );

		expression.append( {
			  id                = "presideobject_formulamatches_#arguments.parentObjectname##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyName#"
			, fields            = { _stringOperator={ fieldType="operator", variety="string", required=false, default="eq" }, value={ fieldType="text", required=false, default="" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.TextFormulaPropertyMatches.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.TextFormulaPropertyMatches.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.TextFormulaPropertyMatches.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.TextFormulaPropertyMatches.getText"
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

	private struct function _createEnumFormulaMatchesExpression( required string objectName, required string propertyName, required string enum, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments );

		expression.append( {
			  id                = "presideobject_enumFormulaMatches_#arguments.parentObjectname##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyName#"
			, fields            = { _is={ fieldType="boolean", variety="isIsNot", required=false, default=true }, enumValue={ fieldType="enum", enum=arguments.enum, required=false, default="", defaultLabel="rules.dynamicExpressions:enumFormulaPropertyMatches.enumValue.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.EnumFormulaPropertyMatches.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.EnumFormulaPropertyMatches.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.EnumFormulaPropertyMatches.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.EnumFormulaPropertyMatches.getText"
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

	private struct function _createBooleanFormulaIsTrueExpression( required string objectName, required string propertyName, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments );

		expression.append( {
			  id                = "presideobject_booleanformulaistrue_#arguments.parentObjectname##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyName#"
			, fields            = { _is={ fieldType="boolean", variety="isIsNot", required=false, default=true } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.BooleanFormulaPropertyIsTrue.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.BooleanFormulaPropertyIsTrue.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.BooleanFormulaPropertyIsTrue.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.BooleanFormulaPropertyIsTrue.getText"
		} );

		return expression;
	}

	private struct function _createDateInRangeExpression( required string objectName, required string propertyName, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments );
		var dbType      = $getPresideObjectService().getObjectPropertyAttribute( arguments.objectName, arguments.propertyName, "dbtype" );
		var isDate      = dbType=="date";

		expression.append( {
			  id                = "presideobject_dateinrange_#arguments.parentObjectname##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyName#"
			, fields            = { _time={ fieldtype="timePeriod", type="alltime", required=false, default="", isDate=isDate } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.DatePropertyInRange.getText"
		} );

		return expression;
	}

	private struct function _createDateFormulaInRangeExpression( required string objectName, required string propertyName, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments );
		var dbType      = $getPresideObjectService().getObjectPropertyAttribute( arguments.objectName, arguments.propertyName, "dbtype" );
		var isDate      = dbType=="date";

		expression.append( {
			  id                = "presideobject_formulainrange_#arguments.parentObjectname##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyName#"
			, fields            = { _time={ fieldtype="timePeriod", type="alltime", required=false, default="", isDate=isDate } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.DateFormulaPropertyInRange.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.DateFormulaPropertyInRange.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.DateFormulaPropertyInRange.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.DateFormulaPropertyInRange.getText"
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

	private struct function _createNumericFormulaComparisonExpression( required string objectName, required string propertyName, required string parentObjectName, required string parentPropertyName  ) {
		var expression  = _getCommonExpressionDefinition( argumentCollection=arguments );

		expression.append( {
			  id                = "presideobject_formulacompares_#arguments.parentObjectname##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyName#"
			, fields            = { _numericOperator={ fieldtype="operator", variety="numeric", required=false, default="eq" }, value={ fieldtype="number", required=false, default=0 } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.NumericFormulaPropertyCompares.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.NumericFormulaPropertyCompares.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.NumericFormulaPropertyCompares.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.NumericFormulaPropertyCompares.getText"
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
			, fields            = { _numericOperator={ fieldtype="operator", variety="numeric", required=false, default="eq" }, value={ fieldType="number", required=false, default=0 }, savedFilter={ fieldType="filter", object=propertyDefinition.relatedTo, multiple=false, quickadd=true, quickedit=true, required=false, default="", defaultLabel="rules.dynamicExpressions:manyToManyCount.savedFilter.default.label" } }
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
			, fields            = { _possesses={ fieldType="boolean", variety=possessesVariety, required=false, default=true }, value={ fieldType="number", required=false, default=0 }, savedFilter={ fieldType="filter", object=propertyDefinition.relatedTo, multiple=false, quickadd=true, quickedit=true, required=false, default="", defaultLabel="rules.dynamicExpressions:manyToManyCount.savedFilter.default.label" } }
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
			, fields            = { _numericOperator={ fieldtype="operator", variety="numeric", required=false, default="eq" }, value={ fieldType="number", required=false, default=0 }, savedFilter={ fieldType="filter", object=propertyDefinition.relatedTo, multiple=false, quickadd=true, quickedit=true, required=false, default="", defaultLabel="rules.dynamicExpressions:oneToManyCount.savedFilter.default.label" } }
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
			, fields            = { _is={ fieldType="boolean", variety=possessesVariety, required=false, default=true }, value={ fieldType="number", required=false, default=0 }, savedFilter={ fieldType="filter", object=propertyDefinition.relatedTo, multiple=false, quickadd=true, quickedit=true, required=false, default="", defaultLabel="rules.dynamicExpressions:oneToManyHas.savedFilter.default.label" } }
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

	private struct function _createOutdatedTranslationExpression( required string objectName, required struct propertyDefinition, required string parentObjectName, required string parentPropertyName  ) {
		var expression       = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName=propertyDefinition.name );
		var possessesVariety = _getBooleanVariety( arguments.objectName, arguments.propertyDefinition.name, "possesses" );

		expression.append( {
			  id                = "presideobject_outdatedtranslation_#arguments.parentObjectName##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyDefinition.name#"
			, fields            = { _possesses={ fieldType="boolean", variety=possessesVariety, required=false, default=true }, value={ fieldType="object", object="multilingual_language", multiple=true, required=true, default="", defaultLabel="rules.dynamicExpressions:outdatedTranslation.value.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.OutdatedTranslation.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.OutdatedTranslation.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.OutdatedTranslation.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.OutdatedTranslation.getText"
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

	private struct function _createTranslationExistsExpression( required string objectName, required struct propertyDefinition, required string parentObjectName, required string parentPropertyName  ) {
		var expression       = _getCommonExpressionDefinition( argumentCollection=arguments, propertyName=propertyDefinition.name );
		var possessesVariety = _getBooleanVariety( arguments.objectName, arguments.propertyDefinition.name, "possesses" );

		expression.append( {
			  id                = "presideobject_translationexists_#arguments.parentObjectName##arguments.parentPropertyName##arguments.objectName#.#arguments.propertyDefinition.name#"
			, fields            = { _possesses={ fieldType="boolean", variety=possessesVariety, required=false, default=true }, value={ fieldType="object", object="multilingual_language", multiple=true, required=true, default="", defaultLabel="rules.dynamicExpressions:TranslationExists.value.default.label" }, savedFilter={ fieldType="filter", object=propertyDefinition.relatedTo, multiple=false, quickadd=true, quickedit=true, required=false, default="", defaultLabel="rules.dynamicExpressions:TranslationExists.savedFilter.default.label" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.TranslationExists.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.TranslationExists.prepareFilters"
			, labelHandler      = "rules.dynamic.presideObjectExpressions.TranslationExists.getLabel"
			, textHandler       = "rules.dynamic.presideObjectExpressions.TranslationExists.getText"
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
		var commonArgs   = { objectName   = objectName };

		if ( propertyName.len() ) {
			commonArgs.propertyName = propertyName;
		}

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

	/**
	 * In addition to auto expressions being generated per property on an object,
	 * developers can specify additional relationship properties + property *chains*
	 * to have a related object's auto generated rules also applied to the source
	 * object. This logic deals with creating those
	 */
	private array function _createExpressionsForRelatedObjectProperties(
		  required string objectName
		, required string relatedObjectPath
	) {
		var poService              = $getPresideObjectService();
		var currentObjectName      = arguments.objectName;
		var parentPropertyName     = ListChangeDelims( arguments.relatedObjectPath, "$", "." );
		var supportedRelationships = [ "many-to-one", "many-to-many", "one-to-many" ];
		var relationshipHelpers    = [];
		var expressions            = [];

		for( var propName in ListToArray( arguments.relatedObjectPath, "." ) ) {
			var prop    = poService.getObjectProperty( currentObjectName, propName );
			var isValid = Len( prop.relatedTo ?: "" ) && ArrayFindNoCase( supportedRelationships, prop.relationship ?: "" );

			if ( !isValid ) {
				return [];
			}

			ArrayAppend( relationshipHelpers,  _prepareRelatedObjectRelationshipHelpers(
				  objectName         = prop.relatedTo
				, parentObjectName   = currentObjectName
				, parentPropertyName = propName
				, parentProperty     = prop
			) );

			currentObjectName = prop.relatedto;
		}

		var properties = $getPresideObjectService().getObjectProperties( currentObjectName );
		for( var propName in properties ) {
			ArrayAppend( expressions, generateExpressionsForProperty(
				  objectName         = currentObjectName
				, propertyDefinition = properties[ propName ]
				, parentObjectName   = arguments.objectName
				, parentPropertyName = parentPropertyName
			), true );
		}

		// wrap expressions using a handler designed for related property filtering
		for( var expression in expressions ) {
			expression.expressionHandlerArgs.originalFilterHandler = expression.filterHandler;
			expression.expressionHandlerArgs.relationshipHelpers   = relationshipHelpers;

			expression.filterHandlerArgs.originalFilterHandler = expression.filterHandler;
			expression.filterHandlerArgs.relationshipHelpers   = relationshipHelpers;

			expression.expressionHandler = "rules.dynamic.presideObjectExpressions._relatedObjectExpressions.evaluateExpression";
			expression.filterHandler     = "rules.dynamic.presideObjectExpressions._relatedObjectExpressions.prepareFilters";
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

	private struct function _prepareRelatedObjectRelationshipHelpers(
		  required string objectName
		, required string parentObjectName
		, required string parentPropertyName
		, required struct parentProperty
	) {
		var helpers = {
			  objectName = arguments.objectName
		};
		switch( arguments.parentProperty.relationship ) {
			case "many-to-one":
				helpers.filterArgs = _getOuterJoinForManyToOne( argumentCollection=arguments );
			break;

			case "one-to-many":
				helpers.filterArgs = _getOuterJoinForOneToMany( argumentCollection=arguments );
			break;

			case "many-to-many":
				helpers.filterArgs = _getFilterJoinsForManyToMany( argumentCollection=arguments );
			break;
		}

		return helpers;
	}


	private struct function _getOuterJoinForManyToOne() {
		var idField    = $getPresideObjectService().getIdField( arguments.objectName );
		var innerField = "#arguments.objectName#.#idField#";
		var outerField = "#arguments.parentObjectName#.#arguments.parentPropertyName#";

		return { filter = $helpers.obfuscateSqlForPreside( "#innerField# = #outerField#" ) };
	}

	private struct function _getOuterJoinForOneToMany() {
		var relationshipKey = $getPresideObjectService().getObjectPropertyAttribute( objectName=arguments.parentObjectName, propertyName=arguments.parentPropertyName, attributeName="relationshipKey", defaultValue=arguments.parentObjectName );
		var idField = $getPresideObjectService().getIdField( arguments.parentObjectName );
		var innerField = "#arguments.objectName#.#relationshipKey#";
		var outerField = "#arguments.parentObjectName#.#idField#";

		return { filter = $helpers.obfuscateSqlForPreside( "#innerField# = #outerField#" ) };
	}

	private struct function _getFilterJoinsForManyToMany() {
		var idField    = $getPresideObjectService().getIdField( arguments.parentObjectName );
		var outerField = "#arguments.parentObjectName#.#idField#";

		var prop       = $getPresideObjectService().getObjectProperty( objectName=arguments.parentObjectName, propertyName=arguments.parentPropertyName );
		var relatedVia = prop.relatedVia           ?: "";
		var outerFk    = "";

		if ( $helpers.isTrue( prop.relationshipIsSource ?: true ) ) {
			outerFk = prop.relatedViaSourceFk ?: arguments.parentObjectName;
		} else {
			outerFk = prop.relatedViaTargetFk ?: arguments.parentObjectName;
		}
		var innerField = "#relatedVia#.#outerFk#"

		return {
			  filter     = "#innerField# = #$helpers.obfuscateSqlForPreside( outerField )#"
			, forceJoins = "inner"
		};
	}


// GETTERS AND SETTERS
	private any function _getRulesEngineContextService() {
		return _rulesEngineContextService;
	}
	private void function _setRulesEngineContextService( required any rulesEngineContextService ) {
		_rulesEngineContextService = arguments.rulesEngineContextService;
	}
}