/**
 * Expression handler for "Current page is/is not an immediate descendant of any of the following pages:"
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
		var parent       = payload.page.parent_page ?: "";
		var isDescendant = parent.len() && pages.ListFindNoCase( parent );

		return _is ? isDescendant : !isDescendant;
	}

}