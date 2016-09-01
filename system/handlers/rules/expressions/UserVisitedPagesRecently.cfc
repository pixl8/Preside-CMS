/**
 * Expression handler for "User has visited any/all of the following pages"
 *
 * @feature websiteUsers
 */
component {

	property name="websiteUserActionService" inject="websiteUserActionService";

	/**
	 * @expression         true
	 * @expressionContexts webrequest,user
	 * @pages.fieldType    page
	 * @days.fieldLabel    rules.expressions.UserVisitedPagesRecently.webrequest:field.days.config.label
	 */
	private boolean function webRequest(
		  required string  pages
		, required numeric days
		,          boolean _has = true
		,          boolean _all = false
	) {
		var userId = payload.user.id ?: "";
		var since  = DateAdd( "d", -days, Now() );

		if ( pages.listLen() > 1 && _all ) {
			for( var page in pages.listToArray() ) {
				var result = websiteUserActionService.hasPerformedAction(
					  type        = "request"
					, action      = "pagevisit"
					, userId      = userId
					, identifiers = [ page ]
					, since       = since
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
				, since       = since
			);
		}

		return _has ? result : !result;
	}

}