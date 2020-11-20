/**
 * @expressionCategory formbuilder
 * @expressionContexts user
 * @feature            websiteusers
 */
component {

	property name="formBuilderFilterService" inject="formBuilderFilterService";

	/**
	 * @question.fieldtype  formbuilderQuestion
	 * @question.item_type  textinput,textarea,email
	 * @formId.fieldtype    formbuilderForm
	 */
	private boolean function evaluateExpression(
		  required string question
		, required string value
		,          string formId
		,          string  _stringOperator = "eq"
	) {
		var userId = payload.user.id ?: "";

		if ( !userId.len() ) {
			return false;
		}

		return formBuilderFilterService.evaluateQuestionUserLatestResponseMatch(
			  argumentCollection = arguments
			, userId             = userId
			, formId             = payload.formId ?: ""
			, submissionId       = payload.submissionId ?: ""
			, extraFilters       = prepareFilters( argumentCollection=arguments )
		);
	}

	/**
	 * @objects website_user
	 */
	private array function prepareFilters(
		  required string question
		, required string value
		,          string formId             = ""
		,          string _stringOperator    = "contains"
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		return formBuilderFilterService.prepareFilterForUserLatestResponseToTextField( argumentCollection=arguments );
	}

}
