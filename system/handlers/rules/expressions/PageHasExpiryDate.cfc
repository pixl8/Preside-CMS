/**
 * Expression handler for "Current page has/does not have an expiry date"
 *
 */
component {

	/**
	 * @expression true
	 * @expressionContexts webrequest,page
	 */
	private boolean function webRequest(
		required numeric _posesses
	) {
		var expiry = payload.page.expiry_date ?: "";
		var hasExpiry = IsDate( expiry );

		return _posesses ? hasExpiry : !hasExpiry;
	}

}