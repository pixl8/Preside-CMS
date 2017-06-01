/**
 * The website user object represents the login details of someone / something that can log into the front end website (as opposed to the admin)
 *
 *  @dataExportFields id,login_id,email_address,display_name,active,last_logged_in,last_logged_out,last_request_made,datecreated,datemodified
 */
component extends="preside.system.base.SystemPresideObject" labelfield="display_name" output=false displayname="Website user" {
	property name="login_id"                    type="string"   dbtype="varchar" maxLength="255" required=true uniqueindexes="login_id";
	property name="email_address"               type="string"   dbtype="varchar" maxLength="255" required=true uniqueindexes="email";
	property name="password"                    type="string"   dbtype="varchar" maxLength="60"  required=false autofilter=false;
	property name="display_name"                type="string"   dbtype="varchar" maxLength="255" required=true;
	property name="active"                      type="boolean"  dbtype="boolean"                 required=false default=true;
	property name="reset_password_token"        type="string"   dbtype="varchar" maxLength="35"  required=false indexes="resettoken" autofilter=false;
	property name="reset_password_key"          type="string"   dbtype="varchar" maxLength="60"  required=false                      autofilter=false;
	property name="reset_password_token_expiry" type="date"     dbtype="datetime"                required=false                      autofilter=false;
	property name="last_logged_in"              type="date"     dbtype="datetime"                required=false ignoreChangesForVersioning=true;
	property name="last_logged_out"             type="date"     dbtype="datetime"                required=false ignoreChangesForVersioning=true;
	property name="last_request_made"           type="date"     dbtype="datetime"                required=false ignoreChangesForVersioning=true;

	property name="benefits" relationship="many-to-many" relatedTo="website_benefit";

	property name="email_logs" relationship="one-to-many" relatedTo="email_template_send_log" relationshipkey="website_user_recipient" autofilter=false;
	property name="actions"    relationship="one-to-many" relatedTo="website_user_action"     relationshipkey="user"                   autofilter=false;
}