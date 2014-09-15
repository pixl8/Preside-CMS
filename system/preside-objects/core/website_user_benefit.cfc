/**
 * Website user benefits can be tagged against website users (see :doc:`website_user`).
 * Pages in the site tree, assets in the asset manager, and other custom access areas can then be
 * tagged with member benefits to control users' access to multiple areas and actions in the site.
 */
component extends="preside.system.base.SystemPresideObject" output="false" displayName="Website user benefit" {
	property name="label" uniqueindexes="benefit_name";
	property name="description"  type="string"  dbtype="varchar" maxLength="200"  required="false";
}