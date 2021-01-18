/**
 * Expression handler for "User has submitted a form builder form a number of times"
 *
 * @feature websiteUsers
 * @expressionContexts user
 * @expressionCategory website_user
 */
component {
	property name="formBuilderFilterService"   inject="formBuilderFilterService";
	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

	/**
	 * @fbform.fieldType   object
	 * @fbform.object      formbuilder_form
	 * @fbform.multiple    false
	 */
	private boolean function evaluateExpression(
		  required string  fbform
		, required numeric times
		,          string  _numericOperator = "eq"
		,          boolean _has = true
		,          struct  _pastTime
	) {
		var userSubmissions = formBuilderFilterService.getUserSubmissionsRecords(
			  userId = payload.user.id ?: ""
			, formId = arguments.fbform
			, from   = isDate( arguments._pastTime.from ?: "" ) ? arguments._pastTime.from : nullValue()
			, to     = isDate( arguments._pastTime.to   ?: "" ) ? arguments._pastTime.to   : nullValue()
		);

		var result = rulesEngineOperatorService.compareNumbers( userSubmissions.recordcount, arguments._numericOperator, arguments.times );

		return _has ? result : !result;
	}

	/**
	 * @objects website_user
	 *
	 */
	private array function prepareFilters(
		  required string  fbform
		, required numeric times
		,          string  _numericOperator   = "eq"
		,          boolean _has               = true
		,          struct  _pastTime          = {}
		,          string  filterPrefix       = ""
		,          string  parentPropertyName = ""
	) {
		return formBuilderFilterService.prepareFilterForUserSubmittedFormBuilderForm(
			  formId             = arguments.fbform
			, has                = arguments._has
			, qty                = arguments.times
			, qtyOperator        = arguments._numericOperator
			, from               = isDate( arguments._pastTime.from ?: "" ) ? arguments._pastTime.from : nullValue()
			, to                 = isDate( arguments._pastTime.to   ?: "" ) ? arguments._pastTime.to   : nullValue()
			, filterPrefix       = arguments.filterPrefix
			, parentPropertyName = arguments.parentPropertyName
		);
	}

}