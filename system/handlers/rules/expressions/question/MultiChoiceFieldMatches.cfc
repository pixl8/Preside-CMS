/**
 * @expressionContexts webrequest
 * @expressionCategory formbuilder
 * @expressionTags     formbuilderV2Form
 * @feature            rulesEngine and formbuilder
 */
component {

	property name="formBuilderFilterService" inject="formBuilderFilterService";

	 /**
	 * @question.fieldtype     formbuilderQuestion
	 * @question.objectFilters formbuilderMultiChoiceFields
	 * @value.fieldtype        formbuilderQuestionChoiceValue
	 */
	private boolean function evaluateExpression(
		  required string question
		, required string value
		,          string _all = false
	) {
		return formBuilderFilterService.evaluateQuestionSubmissionResponseMatch(
			  argumentCollection = arguments
			, userId             = payload.user.id                            ?: ""
			, formId             = payload.formbuilderSubmission.formId       ?: ""
			, submissionId       = payload.formbuilderSubmission.submissionId ?: ""
			, extraFilters       = prepareFilters( argumentCollection=arguments )
		);
	}

	/**
	 * @objects formbuilder_formsubmission
	 */
	private array function prepareFilters(
		  required string  question
		, required string  value
		,          boolean _all = false
	) {
		return formBuilderFilterService.prepareFilterForSubmissionQuestionResponseMatchesChoiceOptions( argumentCollection=arguments );
	}

}
