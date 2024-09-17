/**
 * Expression handler for "File type for {question} matches"
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
	 * @question.object    formbuilder_question
	 * @question.item_type fileUpload
	 * @filetype.fieldtype formbuilderQuestionFileUploadType
	 */
	private boolean function evaluateExpression(
		  required string  question
		, required string  filetype
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
		  required string question
		, required string filetype
		,          boolean _is = true
	) {
		return formBuilderFilterService.prepareFilterForSubmissionQuestionFileUploadTypeMatches( argumentCollection=arguments );
	}

}
