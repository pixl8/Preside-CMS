/**
 * Expression handler for "User's has performed some action within the last x days"
 *
 * @feature websiteUsers
 * @expressionContexts user
 */
component {

	property name="websiteUserActionService" inject="websiteUserActionService";

	/**
	 * @asset.fieldType    asset
	 * @asset.multiple     false
	 */
	private boolean function evaluateExpression(
		  required string  asset
		,          struct  _pastTime
	) {
		if ( ListLen( action, "." ) != 2 ) {
			return false;
		}

		var lastPerformedDate = websiteUserActionService.getLastPerformedDate(
			  type        = "asset"
			, action      = "download"
			, userId      = payload.user.id ?: ""
			, identifiers = [ arguments.asset ]
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

}