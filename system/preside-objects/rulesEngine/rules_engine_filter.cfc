/**
 * The rules engine filter object represents a globally saved filter
 * that can be used to filter preside object records. See
 * [[rules-engine]] for a detailed guide
 *
 * @labelfield filter_name
 */
component extends="preside.system.base.SystemPresideObject" displayName="Rules engine: filter" {
	property name="filter_name" type="string" dbtype="varchar" maxlength=200 required=true uniqueindexes="name|1";
	property name="object_name" type="string" dbtype="varchar" maxlength=200 required=true uniqueindexes="name|2";
	property name="expressions" type="string" dbtype="text"                  required=true;
}