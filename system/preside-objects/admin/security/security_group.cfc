/**
 * User groups allow you to bulk assign a set of Roles to a number of users.
 *
 * See [[cmspermissioning]] for more information on users and permissioning.
 */
component extends="preside.system.base.SystemPresideObject" output="false" displayName="User group" {
	property name="label" uniqueindexes="role_name";
	property name="description"  type="string"  dbtype="varchar" maxLength="200"  required="false";
	property name="roles"        type="string"  dbtype="varchar" maxLength="1000" required="false" control="rolepicker" multiple="true";
}