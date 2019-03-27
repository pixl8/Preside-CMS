/**
 * A user represents someone who can login to the website administrator.
 *
 * See [[cmspermissioning]] for more information on users and permissioning.
 *
 */
component extends="preside.system.base.SystemPresideObject" labelfield="known_as" output="false" displayName="User" {
	property name="active"                          type="boolean"  dbtype="boolean"                 required=false default=true sortorder=10;
	property name="login_id"                        type="string"   dbtype="varchar" maxLength="50"  required=true  uniqueindexes="login_id" sortorder=20;
	property name="email_address"                   type="string"   dbtype="varchar" maxLength="255" required=false uniqueindexes="email" control="textinput" sortorder=30;
	property name="known_as"                        type="string"   dbtype="varchar" maxLength="50"  required=true sortorder=40;
	property name="user_language"                   type="string"   dbtype="varchar" maxLength="50"  required=false sortorder=50;
	property name="password"                        type="string"   dbtype="varchar" maxLength="60"  required=false autofilter=false renderer="none" sortorder=60;
	property name="reset_password_token"            type="string"   dbtype="varchar" maxLength="35"  required=false autofilter=false indexes="resettoken" renderer="none" sortorder=70;
	property name="reset_password_key"              type="string"   dbtype="varchar" maxLength="60"  required=false autofilter=false                      renderer="none" sortorder=80;
	property name="reset_password_token_expiry"     type="date"     dbtype="datetime"                required=false autofilter=false                      renderer="none" sortorder=90;
	property name="two_step_auth_enabled"           type="boolean"  dbtype="boolean"                 required=false default=false                         renderer="none" sortorder=100;
	property name="two_step_auth_key"               type="string"   dbtype="varchar" maxLength="255" required=false autofilter=false                      renderer="none" sortorder=110;
	property name="two_step_auth_key_created"       type="date"     dbtype="datetime"                required=false                                       renderer="none" sortorder=120;
	property name="two_step_auth_key_in_use"        type="boolean"  dbtype="boolean"                 required=false default=false                                         sortorder=130;
	property name="last_logged_in"                  type="date"     dbtype="datetime"                required=false ignoreChangesForVersioning=true sortorder=140;
	property name="last_logged_out"                 type="date"     dbtype="datetime"                required=false ignoreChangesForVersioning=true sortorder=150;
	property name="last_request_made"               type="date"     dbtype="datetime"                required=false ignoreChangesForVersioning=true sortorder=160;
	property name="subscribed_to_all_notifications" type="boolean"  dbtype="boolean"                 required=false default=false sortorder=170;

	property name="groups" relationship="many-to-many" relatedTo="security_group" sortOrder=1000;
}