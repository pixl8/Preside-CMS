/**
 * Expression handler for "Current page has/does not have an embargo date"
 *
 * @expressionContexts page
 */
component {

	private boolean function evaluateExpression( boolean _posesses = true ) {
		var embargo    = payload.page.embargo_date ?: "";
		var hasEmbargo = IsDate( embargo );

		return _posesses ? hasEmbargo : !hasEmbargo;
	}

}