/**
 * @expressionCategory formbuilderInProgress
 * @expressionContexts webRequest
 * @feature            rulesEngine and formbuilder
 */
component {

	property name="formBuilderService"           inject="FormBuilderService";
	property name="rulesEngineOperatorService"   inject="RulesEngineOperatorService";
	property name="rulesEngineTimePeriodService" inject="RulesEngineTimePeriodService";
	property name="fileTypesService"             inject="FileTypesService";

	/**
	 * @formbuilderForm.fieldType   formbuilderForm
	 * @formbuilderPage.fieldType   formbuilderPage
	 * @formbuilderItem.fieldType   formbuilderPageItem
	 * @formbuilderAnswer.fieldType formbuilderPageAnswer
	 */
	private boolean function evaluateExpression(
		  required string  formbuilderForm
		, required string  formbuilderPage
		, required string  formbuilderItem
		, required string  formbuilderAnswer
		,          boolean _has = true
	) {
		var formId = payload.formbuilderSubmission.id ?: "";

		if ( formId != arguments.formbuilderForm ) {
			return false;
		}

		var page = formBuilderService.getPage( formId=formId, formItemId=formbuilderPage );

		if ( isEmpty( page.page_number ?: 0 ) ) {
			return false;
		}

		var formItem = _getFormItem( formId=formId, pageNumber=page.page_number, formItemId=arguments.formbuilderItem );

		if ( isEmptyString( formItem.id ?: "" ) ) {
			return false;
		}

		var formData        = payload.formbuilderSubmission.data ?: {};
		var formFieldName   = formItem.configuration.name        ?: "";
		var formFieldName   = formItem.configuration.name        ?: "";
		var formFieldValue  = formData[ formFieldName ]          ?: "";

		var ruleConfig   = DeserializeJSON( arguments.formbuilderAnswer );
		var ruleDataType = ruleConfig.dataType ?: "";
		var ruleOperator = ruleConfig.operator ?: "eq";
		var ruleValue    = ruleConfig.value    ?: "";
		var ruleResult   = false;

		switch ( ruleDataType ) {
			case "numeric" :
				ruleResult = rulesEngineOperatorService.compareNumbers(
					  leftHandSide  = Val( formFieldValue )
					, operator      = ruleOperator
					, rightHandSide = Val( ruleValue )
				);
				break;

			case "array"   :
				var ruleValues      = [];
				var formFieldValues = [];

				switch ( formItem.item_type ) {
					case "matrix":
						ruleValues = ListToArray( ruleValue );

						var matrix = runEvent(
							  event          = "formbuilder.item-types.matrix._getQuestionsAndAnswers"
							, prePostExempt  = true
							, private        = true
							, eventArguments = { args={
								  itemConfiguration = formItem.configuration ?: {}
								, response          = formFieldValue
							  } }
						);

						var ruleProperty = ruleConfig.property ?: "";
						for ( var item in matrix ) {
							if ( ruleProperty == ( item.question ?: "" ) && !isEmptyString( item.answer ?: "" ) ) {
								if ( ArrayContainsNoCase( [ "allof", "noneof" ], ruleOperator ) ) {
									ArrayAppend( formFieldValues, item.answer );
								} else {
									formFieldValues = [ item.answer ];
									break;
								}
							}
						}
						break;

					case "fileUpload":
						ruleValues = fileTypesService.expandTypeList( types=ListToArray( ruleValue ) );

						if ( IsStruct( formFieldValue )  ) {
							var tempFileInfo = formFieldValue.tempFileInfo ?: {};

							if ( !IsEmpty( tempFileInfo ) ) {
								var serverFileExt = tempFileInfo.serverFileExt  ?: "";

								if ( !isEmptyString( serverFileExt ) ) {
									formFieldValues = [ serverFileExt ];
								}
							}
						}
						break;

					default:
						var formConfigValues = ListToArray( formItem.configuration.values ?: "", Chr( 10 ) & Chr( 13 ) );
						for ( var formConfigValue in formConfigValues ) {
							if ( Find( formConfigValue, ruleValue ) ) {
								ArrayAppend( ruleValues, formConfigValue );
							}

							if ( Find( formConfigValue, formFieldValue ) ) {
								ArrayAppend( formFieldValues, formConfigValue );
							}
						}
						break;
				}

				switch ( ruleOperator ) {
					case "anyof"    :
						ruleResult = _arrayContainsAnyNoCase( ruleValues, formFieldValues );
						break;

					case "notanyof" :
						ruleResult = !_arrayContainsAnyNoCase( ruleValues, formFieldValues );
						break;

					case "allof"    :
						ruleResult = _arrayContainsAllNoCase( ruleValues, formFieldValues );
						break;

					case "noneof"   :
						ruleResult = !_arrayContainsAllNoCase( ruleValues, formFieldValues );
						break;

					default         :
						break;
				}
				break;

			case "boolean" :
				ruleResult = isTrue( ruleOperator ) ? isTrue( formFieldValue ) : isFalse( formFieldValue );
				break;

			case "string"  :
			default        :
				if ( formItem.item_type == "date" ) {
					if ( IsDate( formFieldValue ) ) {
						var dateTimeValue  = ParseDateTime( formFieldValue );
						var dateRangeValue = rulesEngineTimePeriodService.convertTimePeriodToDateRange( arguments.formbuilderAnswer );

						ruleResult = true;

						if ( IsDate( dateRangeValue.from ?: "" ) ) {
							if ( DateCompare( dateTimeValue, dateRangeValue.from ) == -1 ) {
								ruleResult = false;
							}
						}

						if ( IsDate( dateRangeValue.to ?: "" ) ) {
							if ( DateCompare( dateTimeValue, dateRangeValue.to ) == 1 ) {
								ruleResult = false;
							}
						}
					} else {
						ruleResult = false;
					}
				} else {
					ruleResult = rulesEngineOperatorService.compareStrings(
						  leftHandSide  = formFieldValue
						, operator      = ruleOperator
						, rightHandSide = ruleValue
					);
				}
				break;
		}

		return arguments._has ? ruleResult : !ruleResult;
	}

	private struct function _getFormItem(
		  required string  formId
		, required numeric pageNumber
		, required string  formItemId
	) {
		var formItems = formBuilderService.getFormItems( id=arguments.formId, pageNumber=arguments.pageNumber );

		for ( var formItem in formItems ) {
			if ( formItem.id == arguments.formItemId ) {
				return formItem;
			}
		}

		return {};
	}

	private boolean function _arrayContainsAnyNoCase( required array ruleValues, required array formFieldValues ) {
		for ( var ruleValue in arguments.ruleValues ) {
			if ( ArrayContainsNoCase( arguments.formFieldValues, ruleValue ) ) {
				return true;
			}
		}

		return false;
	}

	private boolean function _arrayContainsAllNoCase( required array ruleValues, required array formFieldValues ) {
		for ( var ruleValue in arguments.ruleValues ) {
			if ( !ArrayContainsNoCase( arguments.formFieldValues, ruleValue ) ) {
				return false;
			}
		}

		return true;
	}

}
