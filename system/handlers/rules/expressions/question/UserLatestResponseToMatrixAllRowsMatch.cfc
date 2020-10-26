/**
 * @expressionCategory formbuilder
 * @expressionContexts user
 * @feature            websiteusers
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="formBuilderService"         inject="formBuilderService";
	property name="formBuilderFilterService"   inject="formBuilderFilterService";

	 /**
	 * @question.fieldtype  formbuilderQuestion
	 * @question.item_type  matrix
	 * @row.fieldtype       formbuilderQuestionMatrixRow
	 * @value.fieldtype     formbuilderQuestionMatrixCol
	 *
	 */
	private boolean function evaluateExpression(
		  required string question
		, required string value
		,          string  _all = false
	) {
		var userId = payload.user.id ?: "";

		if ( !userId.len() ) {
			return false;
		}

		var filter = prepareFilters( argumentCollection = arguments	) ;

		return formBuilderFilterService.evaluateQuestionUserLatestResponseMatch(
			  argumentCollection = arguments
			, userId             = userId
			, formId             = payload.formId ?: ""
			, submissionId       = payload.submissionId ?: ""
			, extraFilters       = filter
		);
	}

	/**
	 * @objects website_user
	 */
	private array function prepareFilters(
		  required string  question
		, required string  value
		,          boolean _all               = false
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
	) {
		return formBuilderFilterService.prepareFilterForUserLatestResponseMatrixAllRowsMatch( argumentCollection=arguments );
	}


}
