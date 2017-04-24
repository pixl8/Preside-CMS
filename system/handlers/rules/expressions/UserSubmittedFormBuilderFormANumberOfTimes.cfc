/**
 * Expression handler for "User has submitted a form builder form a number of times"
 *
 * @feature websiteUsers
 * @expressionContexts user
 * @expressionCategory website_user
 */
component {

	property name="websiteUserActionService" inject="websiteUserActionService";
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
		var userId = payload.user.id ?: "";
		var actionCount = websiteUserActionService.getActionCount(
			  type        = "formbuilder"
			, action      = "submitform"
			, userId      = userId
			, identifiers = [ fbform ]
			, dateFrom    = _pastTime.from ?: ""
			, dateTo      = _pastTime.to   ?: ""
		);

		var result = rulesEngineOperatorService.compareNumbers( actionCount, arguments._numericOperator, arguments.times );

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
		return websiteUserActionService.getUserPerformedActionFilter(
			  action             = "submitform"
			, type               = "formbuilder"
			, has                = arguments._has
			, datefrom           = arguments._pastTime.from ?: ""
			, dateto             = arguments._pastTime.to   ?: ""
			, identifiers        = [ arguments.fbform ]
			, qty                = arguments.times
			, qtyOperator        = arguments._numericOperator
			, filterPrefix       = arguments.filterPrefix
			, parentPropertyName = arguments.parentPropertyName
		);
	}

}