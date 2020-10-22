/**
 * Expression handler for "Date {question} matches"
 *
 * @expressionContexts webrequest
 * @expressionCategory formbuilder
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="formBuilderService"         inject="formBuilderService";
	property name="formBuilderFilterService"   inject="formBuilderFilterService";

	/**
	 * @question.fieldtype  formbuilderQuestion
	 * @question.item_type  date
	 * @dateFrom.fieldtype  date
	 * @dateTo.fieldtype    date
	 */
	private boolean function evaluateExpression(
		  required string question
		, required string  dateFrom
		, required string  dateTo
		,          boolean _is = true

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
		, required string dateFrom
		, required string dateTo
		, required boolean _is
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		return formBuilderFilterService.prepareFilterForSubmissionQuestionResponseDateComparison( argumentCollection=arguments );
	}

}
