/**
 * @expressionCategory formbuilder
 * @expressionContexts user
 * @expressionTags     formbuilderV2Form
 * @feature            rulesEngine and websiteusers and formbuilder
 */
component {

	property name="formBuilderFilterService" inject="formBuilderFilterService";

	/**
	 * @question.fieldtype      formbuilderQuestion
	 * @question.objectFilters  formbuilderSingleChoiceFields
	 * @formId.fieldtype        formbuilderForm
	 * @value.fieldtype         formbuilderQuestionChoiceValue
	 */
	private boolean function evaluateExpression(
		  required string question
		, required string value
		,          string formId = ( payload.formId ?: "" )
	) {
		var userId = payload.user.id ?: "";

		if ( !userId.len() ) {
			return false;
		}

		return formBuilderFilterService.evaluateQuestionUserLatestResponseMatch(
			  argumentCollection = arguments
			, userId             = userId
			, formId             = arguments.formId
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
		,          string formId
	) {
		return formBuilderFilterService.prepareFilterForUserLatestResponseToChoiceField( argumentCollection=arguments, _all=false );
	}

}
