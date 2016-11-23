/**
 * Expression handler for "Current page has/does not have a teaser"
 *
 * @expressionContexts page
 * @expressionCategory page
 */
component {

	private boolean function evaluateExpression( boolean _possesses = true ) {
		var hasTeaser = Len( Trim( payload.page.teaser ?: "" ) );

		return _possesses ? hasTeaser : !hasTeaser;
	}

}