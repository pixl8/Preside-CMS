/**
 * Expression handler for "User has visited any/all of the following pages"
 *
 * @feature websiteUsers
 * @expressionContexts user
 */
component {

	property name="websiteUserActionService" inject="websiteUserActionService";

	/**
	 * @assets.fieldType   asset
	 */
	private boolean function evaluateExpression(
		  required string  assets
		,          boolean _has = true
		,          boolean _all = false
		,          struct  _pastTime
	) {
		var userId = payload.user.id ?: "";

		if ( assets.listLen() > 1 && _all ) {
			for( var page in assets.listToArray() ) {
				var result = websiteUserActionService.hasPerformedAction(
					  type        = "asset"
					, action      = "download"
					, userId      = userId
					, identifiers = [ page ]
					, dateFrom    = _pastTime.from ?: ""
					, dateTo      = _pastTime.to   ?: ""
				);

				if ( result != _has ) {
					return false;
				}
			}

			return true;
		} else {
			var result = websiteUserActionService.hasPerformedAction(
				  type        = "asset"
				, action      = "download"
				, userId      = userId
				, identifiers = ListToArray( assets )
				, dateFrom    = _pastTime.from ?: ""
				, dateTo      = _pastTime.to   ?: ""
			);
		}

		return _has ? result : !result;
	}

}