/**
 * The Site object represents a site / microsite that is managed by the CMS.
 *
 * Each site will have its own tree of :doc:`/reference/presideobjects/page` records.
 */
component output=false extends="preside.system.base.SystemPresideObject" labelfield="name" displayName="Site"  {
	property name="name"   type="string" maxlength="200" required="true"  uniqueindexes="sitename";
	property name="domain" type="string" maxlength="255" required="false" uniqueindexes="sitepath|1";
	property name="path"   type="string" maxlength="255" required="false" uniqueindexes="sitepath|2";
}