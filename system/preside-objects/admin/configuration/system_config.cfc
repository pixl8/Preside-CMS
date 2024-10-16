/**
 * The system config object is used to store system settings (see :doc:`/devguides/systemsettings`).
 *
 * See :doc:`/devguides/permissioning` for more information on permissioning.
 *
 * @feature systemConfiguration
 */
component output="false" extends="preside.system.base.SystemPresideObject" labelfield="setting" displayname="System config" feature="systemConfiguration" {

	property name="site" relationship="many-to-one" relatedTo="site" uniqueindexes="categorysetting|1" feature="sites";

	property name="category"  type="string" dbtype="varchar" maxlength="50" required="true"  uniqueindexes="categorysetting|2";
	property name="setting"   type="string" dbtype="varchar" maxlength="50" required="true"  uniqueindexes="categorysetting|3";
	property name="value"     type="string" dbtype="mediumtext"             required="false";
	property name="tenant_id" type="string" dbtype="varchar" maxlength="50" required="false" indexes="tenantid";
}
