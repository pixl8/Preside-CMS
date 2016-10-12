/**
 * Expression handler for "Current page has/does not have a teaser"
 *
 * @expressionContexts page
 */
component {

	private boolean function evaluateExpression( boolean _posesses = true ) {
		var hasTeaser = Len( Trim( payload.page.teaser ?: "" ) );

		return _posesses ? hasTeaser : !hasTeaser;
	}

}