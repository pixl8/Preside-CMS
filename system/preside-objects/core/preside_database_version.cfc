/**
 * Object to store information about the current database's
 * compatibility version level of Preside. This is
 * used to determine what database migration scripts
 * to run when changing version of Preside (upgrades and downgrades).
 *
 * @nolabel
 * @versioned false
 *
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="version_number" type="string" dbtype="varchar" maxlength=100 required=true;
}