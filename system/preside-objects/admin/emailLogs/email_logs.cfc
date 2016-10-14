/**
 * The email logs object is used to store all email activities from the site.
 */
component output="false" extends="preside.system.base.SystemPresideObject" labelfield="emailLogs" displayname="Email Logs" {
	property name="from_address" type="string"  dbtype="varchar" maxLength="100"  required=true ;
	property name="to_address"   type="string"  dbtype="varchar" maxLength="100"  required=true ;
	property name="subject"      type="string"  dbtype="varchar" maxLength="500"  required=true ;
	property name="text_body"    type="string"  dbtype="text"                     required=false;
	property name="html_body"    type="string"  dbtype="text"                     required=false;
	property name="status"       type="string"  dbtype="varchar" maxLength="30"   required=true ;
}