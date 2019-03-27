/**
 * The website user action object represents an occurence of some action
 * that the user/visitor performed. i.e. login, logout, update profile, etc.
 *
 * @nolabel
 * @versioned false
 */
component extends="preside.system.base.SystemPresideObject" displayname="Website user action" {
	property name="user" relationship="many-to-one" relatedTo="website_user"  required=false indexes="user";

	property name="visitor"    type="string"  dbtype="varchar" maxlength=35                 indexes="visitor";
	property name="session_id" type="string"  dbtype="varchar" maxlength=255                indexes="session";
	property name="action"     type="string"  dbtype="varchar" maxLength=100  required=true  indexes="action";
	property name="type"       type="string"  dbtype="varchar" maxLength=100  required=true  indexes="type";
	property name="identifier" type="string"  dbtype="varchar" maxLength=100                indexes="identifier";
	property name="detail"     type="string"  dbtype="text"                   required=true;
	property name="uri"        type="string"  dbtype="varchar" maxLength=2083 required=true;
	property name="user_ip"    type="string"  dbtype="varchar" maxLength=255  required=true;
	property name="user_agent" type="string"  dbtype="text"                   required=false;

	property name="datecreated" indexes="logged";
}