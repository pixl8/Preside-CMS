/**
 * Object to store history of ran db migrations
 *
 * @labelfield     migration_key
 * @noId           true
 * @noDateModified true
 * @versioned      false
 *
 */
component extends="preside.system.base.SystemPresideObject" {
    property name="migration_key" required=true type="string" dbtype="varchar" maxlength=100 uniqueindexes="migrationkey";
}