/**
 * Expression handler for "Current page is/is not available to internal search engine"
 *
 * @expressionContexts page
 */
component {

	property name="siteTreeService" inject="siteTreeService";

	private boolean function evaluateExpression( boolean _is = true ) {
		var availability = siteTreeService.getPageProperty(
			  propertyName = "internal_search_access"
			, page         = payload.page           ?: {}
			, ancestors    = payload.page.ancestors ?: []
			, defaultValue = "inherit"
			, cascading    = true
		);
		var isAvailable = ( availability != "block" );

		return _is ? isAvailable : !isAvailable;
	}

}