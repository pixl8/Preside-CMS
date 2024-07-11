/**
 * @expressionCategory formbuilder
 * @expressionContexts user
 * @expressionTags     formbuilderV2Form
 * @feature            rulesEngine and websiteusers and formbuilder
 */
component {

	property name="formBuilderFilterService" inject="formBuilderFilterService";

	/**
	 * @question.fieldtype  formbuilderQuestion
	 * @question.item_type  date
	 * @formId.fieldtype    formbuilderForm
	 * @_time.isDate
	 */
	private boolean function evaluateExpression(
		  required string question
		,          string formId = ""
		,          struct _time  = {}
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
		,          string formId = ""
		,          struct _time  = {}
	){
		return formBuilderFilterService.prepareFilterForUserLatestResponseToDateField( argumentCollection=arguments );
	}

}
