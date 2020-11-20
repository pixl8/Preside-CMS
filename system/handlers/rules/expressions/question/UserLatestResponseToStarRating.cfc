/**
 * @expressionCategory formbuilder
 * @expressionContexts user
 * @feature            websiteusers
 */
component {

	property name="formBuilderFilterService" inject="formBuilderFilterService";

	/**
	 * @question.fieldtype  formbuilderQuestion
	 * @question.item_type  starRating
	 * @formId.fieldtype    formbuilderForm
	 * @value.fieldtype     formbuilderQuestionStarRatingValue
	 */
	private boolean function evaluateExpression(
		  required string  question
		, required numeric value
		,          string  formId           = ( payload.formId ?: "" )
		,          string  _numericOperator = "eq"
	) {
		var userId = payload.user.id ?: "";

		if ( !userId.len() ) {
			return false;
		}

		return formBuilderFilterService.evaluateQuestionUserLatestResponseMatch(
			  argumentCollection = arguments
			, userId             = userId
			, formId             = arguments.formid
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
