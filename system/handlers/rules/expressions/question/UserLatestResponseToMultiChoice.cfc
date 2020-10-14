/**
 * @expressionCategory formbuilder
 * @expressionContexts user
 * @feature            websiteusers
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="formBuilderService"         inject="formBuilderService";
	property name="formBuilderFilterService"   inject="formBuilderFilterService";

	 /**
	 * @question.fieldtype      formbuilderQuestionMulti
	 * @question.object         formbuilder_question
	 * @question.item_type      checkboxList
	 * @question.questionType   checkbox
	 * @question.multiSelect    true
	 * @value.fieldtype         formbuilderQuestionChoiceValue
	 *
	 */
	private boolean function evaluateExpression(
		  required string question
		, required string value
		,          string  _all = false
	) {
		var filter = prepareFilters( argumentCollection = arguments	);

		return formBuilderFilterService.evaluateQuestionUserLatestResponseMatch(
			  argumentCollection = arguments
			, userId             = payload.user.id
			, formId             = payload.formId ?: ""
			, submissionId       = payload.submissionId ?: ""
			, extraFilters       = filter
		);
	}

	/**
	 * @objects website_user
	 */
	private array function prepareFilters(
		  required string  question
		, required string  value
		,          boolean _all               = false
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
	) {
		return formBuilderFilterService.prepareFilterForUserLatestResponseToChoiceField( argumentCollection=arguments );
	}

}
