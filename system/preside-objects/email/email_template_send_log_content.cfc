/**
 * A log of the email content sent through the templating system, used for resending emails
 *
 * @nolabel       true
 * @versioned     false
 * @feature       emailCenterResend
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="html_body" type="string" dbtype="longtext" required=true;
	property name="text_body" type="string" dbtype="longtext" required=true;
	property name="expires"   type="date"   dbtype="datetime" required=true indexes="content_expires";
}