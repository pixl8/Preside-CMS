/**
 * Expression handler for "Checkbox {question} text matches"
 *
 * @expressionContexts formbuilderSubmission
 * @expressionCategory formbuilder
 * @expressionTags     formbuilderV2Form
 * @feature            rulesEngine and formbuilder
 */
component {

	property name="formBuilderFilterService" inject="formBuilderFilterService";

	/**
	 * @question.fieldtype formbuilderQuestion
	 * @question.item_type checkbox
	 */
	private boolean function evaluateExpression(
		  required string  question
		,          boolean _is = true
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
		,          boolean _is = true
	){
		return formBuilderFilterService.prepareFilterForSubmissionQuestionHasResponded( argumentCollection=arguments, _has = _is );
	}

}
