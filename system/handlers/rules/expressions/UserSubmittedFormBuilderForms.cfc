/**
 * Expression handler for "User has submitted any/all of the following form builder forms"
 *
 * @expressionContexts user
 * @expressionCategory website_user
 * @feature            rulesEngine and websiteUsers and formBuilder
 */
component {

	property name="formBuilderFilterService" inject="formBuilderFilterService";

	/**
	 * @forms.fieldType    object
	 * @forms.object       formbuilder_form
	 */
	private boolean function evaluateExpression(
		  required string  forms
		,          boolean _has = true
		,          boolean _all = false
		,          struct  _pastTime
	) {
		var userId = payload.user.id ?: "";

		if ( !userId.len() ) {
			return !arguments._has;
		}

		return formBuilderFilterService.evaluateUserHasSubmittedForm(
			  argumentCollection = arguments
			, userId             = userId
			, extraFilters       = prepareFilters( argumentCollection=arguments )
		);

	}

	/**
	 * @objects website_user
	 *
	 */
	private array function prepareFilters(
		  required string  forms
		,          boolean _has               = true
		,          boolean _all               = false
		,          struct  _pastTime          = {}
	) {
		return formBuilderFilterService.prepareFilterForUserHasSubmittedFormFilter(
			  formId   = ListToArray( forms )
			, _has     = arguments._has
			, _all     = arguments._all
			, dateFrom = arguments._pastTime.from ?: ""
			, dateTo   = arguments._pastTime.to   ?: ""
		);
	}

}