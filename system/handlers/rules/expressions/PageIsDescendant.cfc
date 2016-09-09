/**
 * Expression handler for "Current page is/is not a descendant of any of the following pages:"
 *
 * @expressionContexts page
 */
component {

	/**
	 * @pages.fieldType page
	 */
	private boolean function evaluateExpression(
		  required string  pages
		,          boolean _is = true
	) {
		var ancestors    = ( payload.page.ancestorList ?: "" ).listToArray();
		var isDescendant = false;

		for( var ancestor in ancestors ) {
			if ( pages.listFindNoCase( ancestor ) ) {
				isDescendant = true;
				break;
			}
		}

		return _is ? isDescendant : !isDescendant;
	}

}