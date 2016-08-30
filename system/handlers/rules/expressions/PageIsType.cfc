/**
 * Expression handler for "Current page is/is not all/any of the following types: {type list}"
 *
 */
component {

	/**
	 * @expression          true
	 * @pagetypes.fieldType pagetype
	 */
	private boolean function webRequest(
		  required string  pagetypes
		,          boolean _is  =true
	) {
		var currentPageType = event.getCurrentPageType();
		var found           = pageTypes.len() && ListFindNoCase( pageTypes, currentPageType );

		return _is ? found : !found;
	}

}