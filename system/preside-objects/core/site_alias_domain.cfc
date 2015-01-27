/**
 * The Site alias domain object represents a single domain that can also be used to serve the site.
 * Good examples are when you have a separate domain for serving the mobile version of the site,
 * i.e. www.mysite.com and m.mysite.com.
 */
component output=false labelfield="none" extends="preside.system.base.SystemPresideObject" displayName="Site alias domain" {
	property name="domain" type="string" dbtype="varchar" maxlength="255" required=true uniqueindexes="sitealias|2";
	property name="site" relationship="many-to-one"                       required=true uniqueindexes="sitealias|1";
}