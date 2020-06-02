/**
 * The page object represents the core data that is stored for all pages in the site tree, regardless of page type.
 */


component extends="preside.system.base.SystemPresideObject" labelfield="title" displayname="Sitetree Page" siteFiltered=true {

<!--- properties --->
	property name="title"        type="string"  dbtype="varchar"  maxLength="200" required=true control="textinput";
	property name="main_content" type="string"  dbtype="text"                     required=false;
	property name="teaser"       type="string"  dbtype="varchar"  maxLength="500" required=false;
	property name="slug"         type="string"  dbtype="varchar"  maxLength="50"  required=false uniqueindexes="slug|2" format="slug" cloneable=true;
	property name="page_type"    type="string"  dbtype="varchar"  maxLength="100" required=true                                             control="pageTypePicker" indexes="pagetype" autofilter=false;
	property name="layout"       type="string"  dbtype="varchar"  maxLength="100" required=false                                            control="pageLayoutPicker";
	property name="sort_order"   type="numeric" dbtype="int"                      required=true                                             control="none" autofilter=false;
	property name="active"       type="boolean" dbtype="boolean"                  required=false default=true;
	property name="trashed"      type="boolean" dbtype="boolean"                  required=false default=false control="none";
	property name="old_slug"     type="string"  dbtype="varchar" maxLength="50"   required=false;

	property name="main_image"       relationship="many-to-one" relatedTo="asset"                   required=false allowedTypes="image" ondelete="set-null-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
	property name="parent_page"      relationship="many-to-one" relatedTo="page"                    required=false                     uniqueindexes="slug|1" control="none"  ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
	property name="created_by"       relationship="many-to-one" relatedTo="security_user"           required=true                                             control="none" generator="loggedInUserId" onupdate="cascade-if-no-cycle-check";
	property name="updated_by"       relationship="many-to-one" relatedTo="security_user"           required=true                                             control="none" generator="loggedInUserId" onupdate="cascade-if-no-cycle-check";
	property name="access_condition" relationship="many-to-one" relatedto="rules_engine_condition"  required=false control="conditionPicker" ruleContext="webrequest";

	property name="internal_search_access"                  type="string"  dbtype="varchar" maxLength="7"    required=false default="inherit" enum="internalSearchAccess";
	property name="search_engine_access"                    type="string"  dbtype="varchar" maxLength="7"    required=false default="inherit" enum="searchAccess";
	property name="author"                                  type="string"  dbtype="varchar" maxLength="100"  required=false;
	property name="browser_title"                           type="string"  dbtype="varchar" maxLength="100"  required=false;
	property name="description"                             type="string"  dbtype="varchar" maxLength="255"  required=false;
	property name="embargo_date"                            type="date"    dbtype="datetime"                 required=false                                                                   control="datetimepicker" indexes="embargodate";
	property name="expiry_date"                             type="date"    dbtype="datetime"                 required=false                                                                   control="datetimepicker" indexes="expirydate";
	property name="access_restriction"                      type="string"  dbtype="varchar" maxLength="7"    required=false default="inherit" enum="pageAccessRestriction";
	property name="iframe_restriction"                      type="string"  dbtype="varchar" maxLength="10"   required=false default="inherit" enum="pageIframeAccessRestriction";
	property name="full_login_required"                     type="boolean" dbtype="boolean"                  required=false default=false;
	property name="grantaccess_to_all_logged_in_users"      type="boolean" dbtype="boolean"                  required=false default=false;
	property name="exclude_from_navigation"                 type="boolean" dbtype="boolean"                  required=false default=false;
	property name="exclude_from_navigation_when_restricted" type="boolean" dbtype="boolean"                  required=false default=false;
	property name="exclude_from_sub_navigation"             type="boolean" dbtype="boolean"                  required=false default=false;
	property name="exclude_children_from_navigation"        type="boolean" dbtype="boolean"                  required=false default=false;
	property name="exclude_from_sitemap"                    type="boolean" dbtype="boolean"                  required=false default=false;
	property name="navigation_title"                        type="string"  dbtype="varchar" maxLength="200"  required=false;

	property name="_hierarchy_id"                    type="numeric" dbtype="int"     maxLength="0"    required=true                                                            uniqueindexes="hierarchyId" autofilter=false;
	property name="_hierarchy_sort_order"            type="string"  dbtype="varchar" maxLength="200"  required=true                                             control="none" indexes="sortOrder"         autofilter=false;
	property name="_hierarchy_lineage"               type="string"  dbtype="varchar" maxLength="200"  required=true                                             control="none" indexes="lineage"           autofilter=false;
	property name="_hierarchy_child_selector"        type="string"  dbtype="varchar" maxLength="200"  required=true                                             control="none"                             autofilter=false;
	property name="_hierarchy_depth"                 type="numeric" dbtype="int"                      required=true                                             control="none" indexes="depth";
	property name="_hierarchy_slug"                  type="string"  dbtype="varchar" maxLength="2000" required=true                                             control="none"                             autofilter=false;


	property name="child_pages" relationship="one-to-many" relatedTo="page" relationshipKey="parent_page";

	/**
	 * This method is used internally by the Sitetree Service to ensure
	 * that all child nodes of a page have the most up to date helper fields when the parent node
	 * changes.
	 *
	 * This is implemented using some funky SQL that was beyond the capabilities of the standard
	 * Preside Object Service CRUD methods.
	 *
	 * @oldData.hint Query record of the old parent node data
	 * @newData.hint Struct containing the changed fields on the parent node
	 */
	public void function updateChildHierarchyHelpers( required query oldData, required struct newData ) autodoc=true output=false {
		var q         = new query();
		var sql       = "update #getTableName()# set datemodified = ?";
		var dbAdapter = this.getDbAdapter();

		q.setDatasource( getDsn() );
		q.addParam( value=Now(), cfsqltype="timestamp" );

		for( var field in [ "_hierarchy_lineage", "_hierarchy_slug", "_hierarchy_depth", "_hierarchy_sort_order", "trashed" ] ) {
			if ( StructKeyExists( arguments.newData, field ) ) {
				switch( field ) {
					case "_hierarchy_lineage":
						sql &= ', _hierarchy_child_selector = #dbAdapter.getConcatenationSql( '?', 'Right( _hierarchy_child_selector, #dbAdapter.getLengthFunctionSql( '_hierarchy_child_selector' )# - ? )')#';
						q.addParam( value=arguments.newData[ field ]          , cfsqltype="varchar" );
						q.addParam( value=Len( arguments.oldData[ field ][1] ), cfsqltype="integer" );
						// deliberate no break!

					case "_hierarchy_slug":
					case "_hierarchy_sort_order":
						sql &= ', #field# = #dbAdapter.getConcatenationSql( '?', 'Right( #field#, #dbAdapter.getLengthFunctionSql( field )# - ? )' )#';
						q.addParam( value=arguments.newData[ field ]          , cfsqltype="varchar" );
						q.addParam( value=Len( arguments.oldData[ field ][1] ), cfsqltype="integer" );
						break;


					case "_hierarchy_depth":
						sql &= ', #field# = #field# - ?';
						q.addParam( value=arguments.oldData[ field ][1] - arguments.newData[ field ], cfsqltype="integer" );
						break;

					case "trashed":
						sql &= ', #field# = ?';
						q.addParam( value=( arguments.newData.trashed ? 1 : 0 ), cfsqltype="bit" );
						break;

				}
			}
		}

		sql &= " where  _hierarchy_lineage like ? and site = ?";
		q.addParam( value=arguments.oldData._hierarchy_child_selector, cfsqltype="varchar" );
		q.addParam( value=arguments.oldData.site, cfsqltype="varchar" );

		q.setSQL( sql );
		q.execute();
	}
}