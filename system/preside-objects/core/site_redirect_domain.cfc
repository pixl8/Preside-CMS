/**
 * The Site redirect domain object represents a single domain that will permanently redirect to the
 * default domain for a site.
 */
component output=false labelfield="none" extends="preside.system.base.SystemPresideObject" displayName="Site redirect domain" {
	property name="domain" type="string" dbtype="varchar" maxlength="255" required=true uniqueindexes="sitedomain|2";
	property name="site" relationship="many-to-one"                       required=true uniqueindexes="sitedomain|1";
}