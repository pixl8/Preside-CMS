/**
 * Expression handler for "User's has submitted a specific form within the last x days"
 *
 * @feature websiteUsers
 * @expressionContexts user
 */
component {

	property name="websiteUserActionService"   inject="websiteUserActionService";

	/**
	 * @fbform.fieldType   object
	 * @fbform.object      formbuilder_form
	 * @fbform.multiple    false
	 */
	private boolean function evaluateExpression(
		  required string  fbform
		,          struct  _pastTime
	) {
		if ( ListLen( action, "." ) != 2 ) {
			return false;
		}

		var lastPerformedDate = websiteUserActionService.getLastPerformedDate(
			  type        = "formbuilder"
			, action      = "submitform"
			, userId      = payload.user.id ?: ""
			, identifiers = [ arguments.fbform ]
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