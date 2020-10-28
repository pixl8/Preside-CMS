/**
 * Expression handler for "Checkbox {question} text matches"
 *
 * @expressionContexts  formbuilderSubmission
 * @expressionCategory  formbuilder
 * @expressionTags      formbuilderV2Form
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="formBuilderService"         inject="formBuilderService";
	property name="formBuilderFilterService"   inject="formBuilderFilterService";

	/**
	 * @question.fieldtype  formbuilderQuestion
	 * @question.item_type  checkbox
	 *
	 */
	private boolean function evaluateExpression(
		  required string  question
		,          boolean _is = true
	) {
		var filter = prepareFilters( argumentCollection = arguments	);

		return formBuilderFilterService.evaluateQuestionResponseMatch(
			  argumentCollection = arguments
			, userId             = payload.user.id
			, formId             = payload.formId ?: ""
			, submissionId       = payload.submissionId ?: ""
			, extraFilters       = filter
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
