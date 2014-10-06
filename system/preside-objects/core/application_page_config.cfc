/**
 * The Application Page Config object stores configuration key value pairs for application pages.
 * \n
 * See :doc:`/devguides/applicationpages`
 */
component extends="preside.system.base.SystemPresideObject" nolabel=true displayname="Application page config" siteFiltered=true output=false {
	property name="page_id"      type="string" dbtype="varchar" maxlength="200" required="true"  uniqueindexes="pagesetting|1";
	property name="setting_name" type="string" dbtype="varchar" maxlength="50"  required="true"  uniqueindexes="pagesetting|2";
	property name="value"        type="string" dbtype="text"                    required="false";
}