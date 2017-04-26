/**
 * Expression handler for "User has performed action a number of times "
 *
 * @feature websiteUsers
 * @expressionContexts user
 * @expressionCategory website_user
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="websiteUserActionService"   inject="websiteUserActionService";

	/**
	 * @action.fieldType   websiteUserAction
	 * @action.multiple    false
	 */
	private boolean function evaluateExpression(
		  required string  action
		, required numeric times
		,          boolean _has            = true
		,          string _numericOperator = "eq"
		,          struct _pastTime
	) {
		if ( ListLen( action, "." ) != 2 ) {
			return false;
		}

		var actionCount = websiteUserActionService.getActionCount(
			  type   = ListFirst( action, "." )
			, action = ListLast( action, "." )
			, userId = payload.user.id ?: ""
			, dateFrom = _pastTime.from ?: ""
			, dateTo   = _pastTime.to   ?: ""
		);
		var result = rulesEngineOperatorService.compareNumbers( actionCount, arguments._numericOperator, arguments.times );

		return _has ? result : !result;
	}

	/**
	 * @objects website_user
	 *
	 */
	private array function prepareFilters(
		  required string  action
		, required numeric times
		,          boolean _has               = true
		,          string  _numericOperator   = "eq"
		,          struct  _pastTime          = {}
		,          string  filterPrefix       = ""
		,          string  parentPropertyName = ""
	) {
		return websiteUserActionService.getUserPerformedActionFilter(
			  action             = ListRest( arguments.action, "." )
			, type               = ListFirst( arguments.action, "." )
			, has                = arguments._has
			, datefrom           = arguments._pastTime.from ?: ""
			, dateto             = arguments._pastTime.to   ?: ""
			, qty                = arguments.times
			, qtyOperator        = arguments._numericOperator
			, filterPrefix       = arguments.filterPrefix
			, parentPropertyName = arguments.parentPropertyName
		);
	}

}