/**
 * Expression handler for "Current page has/does not have a main image"
 *
 * @expressionContexts page
 */
component {

	private boolean function evaluateExpression( boolean _posesses = true ) {
		var hasImage = Len( Trim( payload.page.main_image ?: "" ) );

		return _posesses ? hasImage : !hasImage;
	}

}