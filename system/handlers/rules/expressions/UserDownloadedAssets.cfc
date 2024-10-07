/**
 * Expression handler for "User has downloaded any/all of the following assets"
 *
 * @expressionContexts user
 * @expressionCategory website_user
 * @feature            rulesEngine and websiteUsers and assetManager
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

	/**
	 * @objects website_user
	 *
	 */
	private array function prepareFilters(
		  required string  assets
		,          boolean _has      = true
		,          boolean _all      = false
		,          struct  _pastTime = {}
	) {
		return websiteUserActionService.getUserPerformedActionFilter(
			  action         = "download"
			, type           = "asset"
			, has            = arguments._has
			, datefrom       = arguments._pastTime.from ?: ""
			, dateto         = arguments._pastTime.to   ?: ""
			, identifiers    = arguments.assets.listToArray()
			, allIdentifiers = arguments._all
		);
	}

}