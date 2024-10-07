/**
 * Expression handler for "Date {question} matches"
 *
 * @expressionContexts webrequest
 * @expressionCategory formbuilder
 * @expressionTags     formbuilderV2Form
 * @feature            rulesEngine and formbuilder
 */
component {

	property name="formBuilderFilterService" inject="formBuilderFilterService";

	/**
	 * @question.fieldtype formbuilderQuestion
	 * @question.item_type date
	 * @_time.isDate
	 */
	private boolean function evaluateExpression(
		  required string question
		,          struct _time = {}
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
		  required string question
		,          struct _time = {}
	) {
		return formBuilderFilterService.prepareFilterForSubmissionQuestionResponseDateComparison( argumentCollection=arguments );
	}

}
