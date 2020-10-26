/**
 * @expressionContexts webrequest
 * @expressionCategory formbuilder
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="formBuilderService"         inject="formBuilderService";
	property name="formBuilderFilterService"   inject="formBuilderFilterService";

	 /**
	 * @question.fieldtype  formbuilderQuestion
	 * @question.item_type  matrix
	 * @value.fieldtype     formbuilderQuestionMatrixCol
	 *
	 */
	private boolean function evaluateExpression(
		  required string question
		, required string value
		,          string _all = false
	) {
		var filter = prepareFilters( argumentCollection = arguments ) ;

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
		  required string  question
		, required string  value
		,          boolean _all               = false
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
	) {
		return formBuilderFilterService.prepareFilterForSubmissionQuestionMatrixAllRowsMatch( argumentCollection=arguments );
	}
}
