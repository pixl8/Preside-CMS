/**
 * User groups allow you to bulk assign a set of Roles to a number of users.
 *
 * See [[cmspermissioning]] for more information on users and permissioning.
 *
 * @datamanagerEnabled true
 * @feature            admin
 */
component extends="preside.system.base.SystemPresideObject" output="false" displayName="User group" {
	property name="label" uniqueindexes="role_name" sortorder=10;
	property name="description"  type="string"  dbtype="varchar" maxLength="200"  required="false" sortorder=20;
	property name="roles"        type="string"  dbtype="varchar" maxLength="1000" required="false" control="rolepicker" multiple="true" sortorder=40 renderer="adminGroupRoles";
	property name="is_catch_all" type="boolean" dbtype="boolean"                  required="false" control="none";

	property name="users" relationship="many-to-many" relatedTo="security_user" sortOrder=30 adminRenderer="objectRelatedRecordsList";
}