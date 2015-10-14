/**
 * A context permission records a grant or deny permission for a given user user group, permission key and context.
 *
 * See [[cmspermissioning]] for more information on permissioning.
 *
 */
component extends="preside.system.base.SystemPresideObject" displayname="Context permission" noLabel="true" output="false" {

	property name="permission_key" type="string" dbtype="varchar" maxlength="100" required=true uniqueindexes="context_permission|1";
	property name="context"        type="string" dbtype="varchar" maxlength="100" required=true uniqueindexes="context_permission|2";
	property name="context_key"    type="string" dbtype="varchar" maxlength="100" required=true uniqueindexes="context_permission|3";
	property name="security_group" relationship="many-to-one"                     required=true uniqueindexes="context_permission|4";
	property name="granted"        type="boolean" dbtype="boolean" required=true;

}