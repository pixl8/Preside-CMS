/**
 * Expression handler for "Current page is/is not all/any of the following types: {type list}"
 *
 * @expressionContexts  page
 */
component {

	/**
	 * @pagetypes.fieldType pagetype
	 */
	private boolean function evaluateExpression(
		  required string  pagetypes
		,          boolean _is  =true
	) {
		var currentPageType = payload.page.page_type ?: "";
		var found           = pageTypes.len() && ListFindNoCase( pageTypes, currentPageType );

		return _is ? found : !found;
	}

}