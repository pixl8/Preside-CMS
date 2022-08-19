/**
 * Expression handler for "Textfield {question} text matches"
 *
 * @expressionContexts  webrequest
 * @expressionCategory  formbuilder
 * @expressionTags      formbuilderV2Form
 */
component {

	property name="formBuilderFilterService" inject="formBuilderFilterService";

	/**
	 * @question.fieldtype  formbuilderQuestion
	 * @question.item_type  textinput,textarea,email
	 */
	private boolean function evaluateExpression(
		  required string question
		, required string value
		,          string  _stringOperator = "eq"
	) {
		var userId = payload.user.id ?: "";

		if ( !userId.len() ) {
			return false;
		}

		return formBuilderFilterService.evaluateQuestionSubmissionResponseMatch(
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
		  required string question
		, required string value
		,          string _stringOperator = "contains"
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	){
		return formBuilderFilterService.prepareFilterForSubmissionQuestionResponseMatchesText( argumentCollection=arguments );
	}

}
