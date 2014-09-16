/**
 * Website benefits can be tagged against website users (see :doc:`website_user`).
 * Pages in the site tree, assets in the asset manager, and other custom access areas can then be
 * tagged with member benefits to control users' access to multiple areas and actions in the site through their benefits.
 *
 * This is also a useful object to extend so that you could add other types of benefits other than page / asset access. For
 * example, you could have a disk space field that can tell the system how much disk space a user has in an uploads folder or
 * some such.
 */
component extends="preside.system.base.SystemPresideObject" output="false" displayName="Website user benefit" {
	property name="label" uniqueindexes="benefit_name";
	property name="description"  type="string"  dbtype="varchar" maxLength="200"  required="false";
}