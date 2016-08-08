/**
 * A rules engine rule is a named rule that provides a data
 * filtering configuration. Named rules can be used by the
 * system for purposes such as deciding whether or not
 * to show some specific content, etc.
 *
 * @labelfield name
 *
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="name"   type="string" dbtype="varchar" maxlength=200 required=true uniqueindexes="rulename";
	property name="type"   type="string" dbtype="varchar" maxlength=100 required=true;
	property name="filter" type="string" dbtype="text";
}