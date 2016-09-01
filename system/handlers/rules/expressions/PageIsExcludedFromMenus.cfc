/**
 * Expression handler for "Current page is/is not excluded from menus"
 *
 */
component {

	/**
	 * @expression true
	 * @expressionContexts webrequest,page
	 */
	private boolean function webRequest(
		boolean _is = true
	) {
		var isExcluded = IsTrue( payload.page.exclude_from_navigation ?: "" ) || IsTrue( payload.page.exclude_from_sub_navigation ?: "" );

		return _is ? isExcluded : !isExcluded;
	}

}