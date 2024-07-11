/**
 * Expression handler for "User has visited a page the last x days"
 *
 * @expressionContexts user
 * @expressionCategory website_user
 * @feature            rulesEngine and websiteUsers and siteTree
 */
component {

	property name="websiteUserActionService" inject="websiteUserActionService";

	/**
	 * @page.fieldType     page
	 * @page.multiple      false
	 */
	private boolean function evaluateExpression(
		  required string  page
		,          struct  _pastTime
	) {
		var lastPerformedDate = websiteUserActionService.getLastPerformedDate(
			  type        = "request"
			, action      = "pagevisit"
			, userId      = payload.user.id ?: ""
			, identifiers = [ arguments.page ]
		);

		if ( !IsDate( lastPerformedDate ) ) {
			return false;
		}

		if ( IsDate( _pastTime.from ?: "" ) && lastPerformedDate < _pastTime.from ) {
			return false;
		}
		if ( IsDate( _pastTime.to ?: "" ) && lastPerformedDate > _pastTime.to ) {
			return false;
		}

		return true;
	}

	/**
	 * @objects website_user
	 *
	 */
	private array function prepareFilters(
		  required string page
		,          struct _pastTime
	) {
		return websiteUserActionService.getUserLastPerformedActionFilter(
			  action     = "pagevisit"
			, type       = "request"
			, datefrom   = arguments._pastTime.from ?: ""
			, dateto     = arguments._pastTime.to   ?: ""
			, identifier = arguments.page
		);
	}

}