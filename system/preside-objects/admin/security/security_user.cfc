/**
 * A user represents someone who can login to the website administrator.
 *
 * See :doc:`/devguides/permissioning` for more information on users and permissioning.
 */
component extends="preside.system.base.SystemPresideObject" labelfield="known_as" output="false" displayName="User" {
	property name="known_as"      type="string"  dbtype="varchar" maxLength="50"  required="true";
	property name="login_id"      type="string"  dbtype="varchar" maxLength="50"  required="true" uniqueindexes="login_id";
	property name="password"      type="string"  dbtype="varchar" maxLength="60"  required="true";
	property name="email_address" type="string"  dbtype="varchar" maxLength="255" required="false" uniqueindexes="email" control="textinput";
	property name="active"        type="boolean" dbtype="boolean" required=false default=true;

	property name="groups" relationship="many-to-many" relatedTo="security_group";
}