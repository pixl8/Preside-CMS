/**
 * Expression handler for "Current page is/is not a descendant of any of the following pages:"
 *
 * @expressionContexts page
 * @expressionCategory page
 */
component {

	property name="presideObjectService" inject="presideObjectService";

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

	/**
	 * @objects page
	 *
	 */
	private array function prepareFilters(
		  required string  pages
		,          boolean _is = true
		,          string  filterPrefix = ""
	) {
		var sql       = "";
		var ancestors = presideObjectService.selectData( objectName="page", filter={ id=pages.listToArray() }, selectFields=["_hierarchy_id"] );
		var delim     = "";
		var params    = {};
		var prefix    = filterPrefix.len() ? filterPrefix : "page";

		for( var ancestor in ancestors ) {
			var paramName = "pageIsDescendant#ancestor._hierarchy_id#";

			sql                 &= delim & "#prefix#._hierarchy_lineage like :#paramName#";
			delim               = " or ";
			params[ paramName ] = { type="cf_sql_varchar", value="%/#ancestor._hierarchy_id#/%" };
		}

		if ( sql.len() ) {
			return [{
				  filter       = "( #sql# )"
				, filterParams = params
			}];
		}

		return [];
	}

}