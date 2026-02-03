/**
 * Expression handler for "User has downloaded an asset a number of times"
 *
 * @expressionContexts user
 * @expressionCategory website_user
 * @feature            rulesEngine and websiteUsers and assetManager
 */
component {

	property name="websiteUserActionService" inject="websiteUserActionService";
	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

	/**
	 * @asset.fieldType    asset
	 * @asset.multiple     false
	 */
	private boolean function evaluateExpression(
		  required string  asset
		, required numeric times
		,          string  _numericOperator = "eq"
		,          boolean _has = true
		,          struct  _pastTime
	) {
		var userId      = payload.user.id ?: "";
		var actionCount = websiteUserActionService.getActionCount(
			  type        = "asset"
			, action      = "download"
			, userId      = userId
			, identifiers = [ asset ]
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
		  required string  asset
		, required numeric times
		,          string  _numericOperator = "eq"
		,          boolean _has             = true
		,          struct  _pastTime        = {}
	) {
		return websiteUserActionService.getUserPerformedActionFilter(
			  action      = "download"
			, type        = "asset"
			, has         = arguments._has
			, datefrom    = arguments._pastTime.from ?: ""
			, dateto      = arguments._pastTime.to   ?: ""
			, identifiers = [ arguments.asset ]
			, qty         = arguments.times
			, qtyOperator = arguments._numericOperator
		);
	}

}