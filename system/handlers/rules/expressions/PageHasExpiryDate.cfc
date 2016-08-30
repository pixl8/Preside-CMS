/**
 * Expression handler for "Current page has/does not have an expiry date"
 *
 */
component {

	/**
	 * @expression true
	 */
	private boolean function webRequest(
		required numeric _has
	) {
		var expiry = event.getPageProperty( "expiry_date" );
		var hasExpiry = IsDate( expiry );

		return _has ? hasExpiry : !hasExpiry;
	}

}