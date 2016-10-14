/**
 * Expression handler for "Current page has/does not have an expiry date"
 *
 * @expressionContexts page
 */
component {

	private boolean function evaluateExpression( boolean _posesses=true ) {
		var expiry = payload.page.expiry_date ?: "";
		var hasExpiry = IsDate( expiry );

		return _posesses ? hasExpiry : !hasExpiry;
	}

}