/**
 * The website user object represents the login details of someone / something that can log into the front end website (as opposed to the admin)
 *
 */
component extends="preside.system.base.SystemPresideObject" labelfield="login_id" output=false displayname="Website user" {
	property name="login_id"      type="string"  dbtype="varchar" maxLength="255" required=true uniqueindexes="login_id";
	property name="email_address" type="string"  dbtype="varchar" maxLength="255" required=true uniqueindexes="email";
	property name="password"      type="string"  dbtype="varchar" maxLength="60"  required=false;
	property name="display_name"  type="string"  dbtype="varchar" maxLength="255" required=true;
	property name="active"        type="boolean" dbtype="boolean"                 required=false default=true;

	property name="benefits" relationship="many-to-many" relatedTo="website_benefit";
}