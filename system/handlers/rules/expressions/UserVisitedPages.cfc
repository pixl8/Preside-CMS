/**
 * Expression handler for "User has visited any/all of the following pages"
 *
 * @expressionContexts user
 * @expressionCategory website_user
 * @feature            rulesEngine and websiteUsers and siteTree
 */
component {

	property name="websiteUserActionService" inject="websiteUserActionService";

	/**
	 * @expression         true
	 * @pages.fieldType    page
	 */
	private boolean function evaluateExpression(
		  required string  pages
		,          boolean _has = true
		,          boolean _all = false
		,          struct  _pastTime
	) {
		var userId = payload.user.id ?: "";

		if ( pages.listLen() > 1 && _all ) {
			for( var page in pages.listToArray() ) {
				var result = websiteUserActionService.hasPerformedAction(
					  type        = "request"
					, action      = "pagevisit"
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
				  type        = "request"
				, action      = "pagevisit"
				, userId      = userId
				, identifiers = ListToArray( pages )
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
		  required string  pages
		,          boolean _has      = true
		,          boolean _all      = false
		,          struct  _pastTime = {}
	) {
		return websiteUserActionService.getUserPerformedActionFilter(
			  action         = "pagevisit"
			, type           = "request"
			, has            = arguments._has
			, datefrom       = arguments._pastTime.from ?: ""
			, dateto         = arguments._pastTime.to   ?: ""
			, identifiers    = arguments.pages.listToArray()
			, allIdentifiers = arguments._all
		);
	}

}