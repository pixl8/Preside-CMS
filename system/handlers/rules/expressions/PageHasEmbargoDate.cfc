/**
 * Expression handler for "Current page has/does not have an embargo date"
 *
 */
component {

	/**
	 * @expression true
	 */
	private boolean function webRequest(
		required numeric _has
	) {
		var embargo    = event.getPageProperty( "embargo_date" );
		var hasEmbargo = IsDate( embargo );

		return _has ? hasEmbargo : !hasEmbargo;
	}

}