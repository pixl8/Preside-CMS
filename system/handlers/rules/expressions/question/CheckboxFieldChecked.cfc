/**
 * Expression handler for "Checkbox {question} text matches"
 *
 * @expressionContexts  formbuilderSubmission
 * @expressionCategory  formbuilder
 * @expressionTags      formbuilderV2Form
 */
component {

	property name="formBuilderFilterService" inject="formBuilderFilterService";

	/**
	 * @question.fieldtype  formbuilderQuestion
	 * @question.item_type  checkbox
	 */
	private boolean function evaluateExpression(
		  required string  question
		,          boolean _is = true
	) {
		var userId = payload.user.id ?: "";

		if ( !userId.len() ) {
			return false;
		}

		return formBuilderFilterService.evaluateQuestionResponseMatch(
			  argumentCollection = arguments
			, userId             = userId
			, formId             = payload.formId ?: ""
			, submissionId       = payload.submissionId ?: ""
			, extraFilters       = prepareFilters( argumentCollection=arguments )
		);
	}

	/**
	 * @objects formbuilder_formsubmission
	 */
	private array function prepareFilters(
		  required string  question
		,          boolean _is                = true
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
	){
		return formBuilderFilterService.prepareFilterForSubmissionQuestionHasResponded( argumentCollection=arguments, _has = _is );
	}

}
