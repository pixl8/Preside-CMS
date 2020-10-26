/**
 * Expression handler for "File type for {question} matches"
 *
 * @expressionContexts webrequest
 * @expressionCategory formbuilder
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="formBuilderService"         inject="formBuilderService";
	property name="formBuilderFilterService"   inject="formBuilderFilterService";

	/**
	 * @question.fieldtype      formbuilderQuestion
	 * @question.object         formbuilder_question
	 * @question.item_type      fileUpload
	 * @filetype.fieldtype      formbuilderQuestionFileUploadType
	 */
	private boolean function evaluateExpression(
		  required string  question
		, required string  filetype
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
		, required string filetype
		,          boolean _is               = true
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		return formBuilderFilterService.prepareFilterForSubmissionQuestionFileUploadTypeMatches( argumentCollection=arguments );
	}

}
