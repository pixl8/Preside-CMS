/**
 * Expression handler for "User has submitted a specific form within the last x days"
 *
 * @expressionContexts user
 * @expressionCategory website_user
 * @feature            rulesEngine and websiteUsers and formbuilder
 */
component {
	property name="formBuilderFilterService" inject="formBuilderFilterService";

	/**
	 * @fbform.fieldType   object
	 * @fbform.object      formbuilder_form
	 * @fbform.multiple    false
	 */
	private boolean function evaluateExpression(
		  required string  fbform
		,          struct  _pastTime
	) {
		var userSubmissions = formBuilderFilterService.getUserSubmissionsRecords(
			  userId = payload.user.id ?: ""
			, formId = arguments.fbform
			, from   = isDate( arguments._pastTime.from ?: "" ) ? arguments._pastTime.from : nullValue()
			, to     = isDate( arguments._pastTime.to   ?: "" ) ? arguments._pastTime.to   : nullValue()
		);

		return booleanFormat( userSubmissions.recordcount );
	}

	/**
	 * @objects website_user
	 *
	 */
	private array function prepareFilters(
		  required string fbform
		,          struct _pastTime
	) {
		return formBuilderFilterService.prepareFilterForUserSubmittedFormBuilderForm(
			  formId = arguments.fbform
			, from   = isDate( arguments._pastTime.from ?: "" ) ? arguments._pastTime.from : nullValue()
			, to     = isDate( arguments._pastTime.to   ?: "" ) ? arguments._pastTime.to   : nullValue()
		);
	}

}