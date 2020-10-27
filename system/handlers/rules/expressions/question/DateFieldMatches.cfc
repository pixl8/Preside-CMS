/**
 * Expression handler for "Date {question} matches"
 *
 * @expressionContexts  webrequest
 * @expressionCategory  formbuilder
 * @exclusionCategories formbuilderV2Form
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="formBuilderService"         inject="formBuilderService";
	property name="formBuilderFilterService"   inject="formBuilderFilterService";

	/**
	 * @question.fieldtype  formbuilderQuestion
	 * @question.item_type  date
	 * @_time.isDate
	 */
	private boolean function evaluateExpression(
		  required string question
		,          struct _time = {}

	) {
		var filter = prepareFilters(
			  argumentCollection = arguments
		);

		return formBuilderFilterService.evaluateQuestionSubmissionResponseMatch(
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
		  required string question
		,          struct _time              = {}
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		return formBuilderFilterService.prepareFilterForSubmissionQuestionResponseDateComparison( argumentCollection=arguments );
	}

}
