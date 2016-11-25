/**
 * A log of every email sent through the templating system
 *
 * @versioned  false
 * @labelfield recipient
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="email_template" relationship="many-to-one" relatedto="email_template" required=true;

	property name="website_user_recipient"  relationship="many-to-one" relatedto="website_user"  required=false;
	property name="security_user_recipient" relationship="many-to-one" relatedto="security_user" required=false;

	property name="recipient" type="string" dbtype="varchar" maxlength=255 required=true;
	property name="sender"    type="string" dbtype="varchar" maxlength=255 required=true;
	property name="subject"   type="string" dbtype="varchar" maxlength=255;

	property name="sent"           type="boolean" dbtype="boolean" default=false;
	property name="delivered"      type="boolean" dbtype="boolean" default=false;
	property name="opened"         type="boolean" dbtype="boolean" default=false;
	property name="marked_as_spam" type="boolean" dbtype="boolean" default=false;
	property name="unsubscribed"   type="boolean" dbtype="boolean" default=false;

	property name="sent_date"           type="date" dbtype="datetime";
	property name="delivered_date"      type="date" dbtype="datetime";
	property name="opened_date"         type="date" dbtype="datetime";
	property name="marked_as_spam_date" type="date" dbtype="datetime";
	property name="unsubscribed_date"   type="date" dbtype="datetime";
}