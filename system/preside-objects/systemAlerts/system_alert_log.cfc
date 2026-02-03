/**
 * @noLabel
 * @noDateCreated
 * @noDateModified
 * @versioned  false
 * @feature    admin
 */

component extends="preside.system.base.SystemPresideObject" {
	property name="type"      type="string"  dbtype="varchar" maxlength=50;
	property name="reference" type="string"  dbtype="varchar" maxlength=50;
	property name="trigger"   type="string"  dbtype="varchar" maxlength=30;
	property name="ms"        type="numeric" dbtype="int";
	property name="run_at"    type="date"    dbtype="datetime";
}