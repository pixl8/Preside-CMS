/**
 * Expression handler for "Current page is/is not all/any of the following types: {type list}"
 *
 * @expressionContexts page
 * @expressionCategory page
 * @feature            rulesEngine and siteTree
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

	/**
	 * @objects page
	 *
	 */
	private array function prepareFilters(
		  required string  pagetypes
		,          boolean _is = true
	) {
		var paramsuffix = CreateUUId().lCase().replace( "-", "", "all" );

		return [ {
			  filter       = "page.page_type #( arguments._is ? 'in' : 'not in' )# (:pagetypes#paramsuffix#)"
			, filterParams = { "pagetypes#paramsuffix#"={ type="cf_sql_varchar", list=true, value=arguments.pageTypes } }
		} ];
	}

}