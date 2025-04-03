/**
 * @expressionCategory formbuilder
 * @expressionContexts formbuilderSubmission
 * @feature            rulesEngine
 */
component {

	property name="formBuilderService"         inject="FormBuilderService";
	property name="rulesEngineOperatorService" inject="RulesEngineOperatorService";

	/**
	 * @formbuilderForm.fieldType    object
	 * @formbuilderForm.object       formbuilder_form
	 * @formbuilderForm.multiple     false
	 * @formbuilderForm.labelUriRoot rules.FormbuilderFormPageFieldMatches:
	 *
	 * @formbuilderPage.fieldType    formbuilderPage
	 *
	 * @formbuilderItem.fieldType    formbuilderPageItem
	 *
	 * @formbuilderAnswer.fieldType  formbuilderPageAnswer
	 */
	private boolean function evaluateExpression(
		  required string formbuilderForm
		, required string formbuilderPage
		, required string formbuilderItem
		, required string formbuilderAnswer
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
		var formFieldValue  = formData[ formFieldName ]          ?: "";
		var formFieldValues = IsJSON( formFieldValue )           ? [] : ListToArray( formFieldValue );

		var ruleConfig   = DeserializeJSON( arguments.formbuilderAnswer );
		var ruleDataType = ruleConfig.dataType ?: "string";
		var ruleOperator = ruleConfig.operator ?: "eq";
		var ruleValue    = ruleConfig.value    ?: "";

		switch ( ruleDataType ) {
			case "string" :
				return rulesEngineOperatorService.compareStrings(
					  leftHandSide  = formFieldValue
					, operator      = ruleOperator
					, rightHandSide = ruleValue
				);

			case "numeric":
				return rulesEngineOperatorService.compareNumbers(
					  leftHandSide  = formFieldValue
					, operator      = ruleOperator
					, rightHandSide = ruleValue
				);

			case "array"  :
				var ruleValues = ListToArray( ruleValue );

				if ( formItem.item_type == "matrix" ) {
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
								formFieldValue = item.answer;
								break;
							}
						}
					}
				}

				switch ( ruleOperator ) {
					case "anyof"    :
						return ArrayContainsNoCase( ruleValues, formFieldValue );

					case "notanyof" :
						return !ArrayContainsNoCase( ruleValues, formFieldValue );

					case "allof"    :
						return _arrayContainsAllNoCase( ruleValues, formFieldValues );

					case "noneof"   :
						return !_arrayContainsAllNoCase( ruleValues, formFieldValues );

					default         :
						return false;
				}

			case "boolean":
				return isTrue( ruleOperator ) ? isTrue( formFieldValue ) : isFalse( formFieldValue );

			default:
				return false;
		}
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

	private boolean function _arrayContainsAllNoCase( required array ruleValues, required array formFieldValues ) {
		for ( var ruleValue in arguments.ruleValues ) {
			if ( !ArrayContainsNoCase( arguments.formFieldValues, ruleValue ) ) {
				return false;
			}
		}

		return true;
	}

}
