/**
 * @expressionCategory formbuilder
 * @expressionContexts user
 * @feature            websiteusers
 */
component {

	property name="formBuilderFilterService" inject="formBuilderFilterService";

	/**
	 * @question.fieldtype  formbuilderQuestion
	 * @formId.fieldtype    formbuilderForm
	 * @question.item_type  number
	 */
	private boolean function evaluateExpression(
		  required string  question
		, required numeric value
		,          string  formId           = ""
		,          string  _numericOperator = "eq"
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
		  required string  question
		, required numeric value
		,          string  formId             = ""
		,          string  _numericOperator   = "eq"
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
	) {
		return formBuilderFilterService.prepareFilterForUserLatestResponseToNumberField( argumentCollection=arguments );
	}

}
