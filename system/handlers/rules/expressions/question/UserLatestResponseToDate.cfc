/**
 *
 * @expressionCategory formbuilder
  * @expressionContexts user
 * @feature            websiteusers
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="formBuilderService"         inject="formBuilderService";
	property name="formBuilderFilterService"   inject="formBuilderFilterService";

	/**
	 * @question.fieldtype      formbuilderQuestion
	 * @question.object         formbuilder_question
	 * @question.item_type      "date"
	 *
	 */
	private boolean function evaluateExpression(
		  required string question
		, required struct _time
	) {
		var filter = prepareFilters( argumentCollection = arguments	) ;

		return formBuilderFilterService.evaluateQuestionUserLatestResponseMatch(
			  argumentCollection = arguments
			, userId             = payload.user.id
			, formId             = payload.formId ?: ""
			, submissionId       = payload.submissionId ?: ""
			, extraFilters       = filter
		);
		return true;
	}

	/**
	 * @objects website_user
	 */
	private array function prepareFilters(
		  required string  question
		, required struct  _time
		,          string  parentPropertyName  = ""
		,          string  filterPrefix        = ""
	){
		return formBuilderFilterService.prepareFilterForUserLatestResponseToDateField( argumentCollection=arguments );
	}

}
