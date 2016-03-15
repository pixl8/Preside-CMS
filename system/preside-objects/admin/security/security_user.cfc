/**
 * A user represents someone who can login to the website administrator.
 *
 * See [[cmspermissioning]] for more information on users and permissioning.
 */
component extends="preside.system.base.SystemPresideObject" labelfield="known_as" output="false" displayName="User" {
	property name="known_as"                        type="string"   dbtype="varchar" maxLength="50"  required=true;
	property name="login_id"                        type="string"   dbtype="varchar" maxLength="50"  required=true  uniqueindexes="login_id";
	property name="email_address"                   type="string"   dbtype="varchar" maxLength="255" required=false uniqueindexes="email" control="textinput";
	property name="password"                        type="string"   dbtype="varchar" maxLength="60"  required=false;
	property name="active"                          type="boolean"  dbtype="boolean"                 required=false default=true;
	property name="reset_password_token"            type="string"   dbtype="varchar" maxLength="35"  required=false indexes="resettoken";
	property name="reset_password_key"              type="string"   dbtype="varchar" maxLength="60"  required=false;
	property name="reset_password_token_expiry"     type="datetime" dbtype="datetime"                required=false;
	property name="two_step_auth_enabled"           type="boolean"  dbtype="boolean"                 required=false default=false;
	property name="two_step_auth_key"               type="string"   dbtype="varchar" maxLength="255" required=false;
	property name="two_step_auth_key_created"       type="datetime" dbtype="datetime"                required=false;
	property name="two_step_auth_key_in_use"        type="boolean"  dbtype="boolean"                 required=false default=false;
	property name="subscribed_to_all_notifications" type="boolean"  dbtype="boolean"                 required=false default=true;
	property name="last_logged_in"                  type="datetime" dbtype="datetime"                required=false ignoreChangesForVersioning=true;
	property name="last_logged_out"                 type="datetime" dbtype="datetime"                required=false ignoreChangesForVersioning=true;
	property name="last_request_made"               type="datetime" dbtype="datetime"                required=false ignoreChangesForVersioning=true;

	property name="groups" relationship="many-to-many" relatedTo="security_group";
}