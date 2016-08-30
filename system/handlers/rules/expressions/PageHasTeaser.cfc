/**
 * Expression handler for "Current page has/does not have a teaser"
 *
 */
component {

	/**
	 * @expression true
	 */
	private boolean function webRequest(
		required numeric _has
	) {
		var hasTeaser = Len( Trim( event.getPageProperty( "teaser" ) ) )

		return _has ? hasTeaser : !hasTeaser;
	}

}