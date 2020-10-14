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
	 * @question.fieldtype      formbuilderQuestion
	 * @question.object         formbuilder_question
	 * @question.item_type      matrix
	 * @row.fieldtype           formbuilderQuestionMatrixRow
	 * @value.fieldtype         formbuilderQuestionMatrixCol
	 *
	 */
	private boolean function evaluateExpression(
		  required string question
		, required string row
		, required string value
		,          string  _all = false
	) {
		var filter = prepareFilters( argumentCollection = arguments	) ;

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
		return formBuilderFilterService.prepareFilterForUserLatestResponseMatrixRowMatches( argumentCollection=arguments );
	}


}
