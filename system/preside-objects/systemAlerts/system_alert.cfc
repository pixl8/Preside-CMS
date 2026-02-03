/**
 * @labelField                   type
 * @labelRenderer                system_alert
 * @versioned                    false
 * @datamanagerEnabled           true
 * @datamanagerGridFields        level,type,context,reference,datecreated,datemodified
 * @datamanagerAllowedOperations navigate,read
 * @dataManagerExportEnabled     false
 * @feature                      admin
 */

component extends="preside.system.base.SystemPresideObject" {
	property name="type"       adminViewGroup="system" type="string" dbtype="varchar" maxlength=50 uniqueIndexes="systemAlert|1" renderer="systemAlertType";
	property name="context"    adminViewGroup="system" type="string" dbtype="varchar" maxlength=20 uniqueIndexes="systemAlert|2" renderer="systemAlertContext";
	property name="reference"  adminViewGroup="system" type="string" dbtype="varchar" maxlength=50 uniqueIndexes="systemAlert|3" renderer="systemAlertReference";
	property name="level"      adminViewGroup="system" type="string" dbtype="varchar" maxlength=10 enum="systemAlertLevel"       renderer="systemAlertLevel";
	property name="data"       adminViewGroup="system" type="string" dbtype="mediumtext";
}