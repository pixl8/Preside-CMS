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
	 * @question.fieldtype  formbuilderQuestion
	 *
	 */
	private boolean function evaluateExpression(
		  required string question
		,          boolean _has = true
	) {
		var userId = payload.user.id ?: "";

		if ( !userId.len() ) {
			return !arguments._has;
		}

		var filter = prepareFilters( argumentCollection = arguments	) ;

		return formBuilderFilterService.evaluateQuestionUserHasResponse(
			  argumentCollection = arguments
			, userId             = userId
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
		,          boolean _has              = true
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
	) {
		return formBuilderFilterService.prepareFilterForUserHasRespondedToQuestion( argumentCollection=arguments );
	}

}
