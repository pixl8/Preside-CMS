/**
 * Expression handler for "Current page is/is not an immediate descendant of any of the following pages:"
 *
 */
component {

	/**
	 * @expression true
	 * @expressionContexts webrequest,page
	 * @pages.fieldType page
	 */
	private boolean function webRequest(
		  required string  pages
		,          boolean _is = true
	) {
		var parent       = payload.page.parent_page ?: "";
		var isDescendant = parent.len() && pages.ListFindNoCase( parent );

		return _is ? isDescendant : !isDescendant;
	}

}