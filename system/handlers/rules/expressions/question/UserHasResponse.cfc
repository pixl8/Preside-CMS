/**
 * @expressionCategory formbuilder
 * @expressionContexts user
 * @feature            websiteusers
 */
component {

	property name="formBuilderFilterService" inject="formBuilderFilterService";

	/**
	 * @question.fieldtype formbuilderQuestion
	 * @formId.fieldtype   formbuilderForm
	 */
	private boolean function evaluateExpression(
		  required string question
		,          string formId = ""
		,          boolean _has = true
	) {
		var userId = payload.user.id ?: "";

		if ( !userId.len() ) {
			return !arguments._has;
		}

		return formBuilderFilterService.evaluateQuestionUserHasResponse(
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
		,          string  formId             = ""
		,          boolean _has               = true
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
	) {
		return formBuilderFilterService.prepareFilterForUserHasRespondedToQuestion( argumentCollection=arguments );
	}

}
