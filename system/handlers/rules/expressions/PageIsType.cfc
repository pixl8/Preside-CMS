/**
 * Expression handler for "Current page is/is not all/any of the following types: {type list}"
 *
 * @expressionContexts page
 * @expressionCategory page
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
		,          boolean _is                = true
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
	) {
		var paramsuffix = CreateUUId().lCase().replace( "-", "", "all" );
		var prefix      = filterPrefix.len() ? filterPrefix : ( parentPropertyName.len() ? parentPropertyName : "page" );

		return [ {
			  filter       = "#prefix#.page_type #( arguments._is ? 'in' : 'not in' )# (:pagetypes#paramsuffix#)"
			, filterParams = { "pagetypes#paramsuffix#"={ type="cf_sql_varchar", list=true, value=arguments.pageTypes } }
		} ];
	}

}