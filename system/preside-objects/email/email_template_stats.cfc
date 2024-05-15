/**
 * Summary table for email activity statistics. Stats grouped
 * in time buckets of 1 hour per email template.
 *
 * @versioned      false
 * @useCache       false
 * @noid           true
 * @nodatemodified true
 * @nodatecreated  true
 * @nolabel        true
 * @feature        emailCenter
 *
 */
component extends="preside.system.base.SystemPresideObject" displayname="Email template" {
	property name="template" relationship="many-to-one" relatedto="email_template"                     uniqueindexes="hourstartemplate|1";
	property name="hour_start" type="numeric" dbtype="int" required=true           indexes="hourstart" uniqueindexes="hourstartemplate|2";

	property name="send_count"         type="numeric" dbtype="int" required=true default=0;
	property name="delivery_count"     type="numeric" dbtype="int" required=true default=0;
	property name="open_count"         type="numeric" dbtype="int" required=true default=0;
	property name="unique_open_count"  type="numeric" dbtype="int" required=true default=0;
	property name="bot_open_count"     type="numeric" dbtype="int" required=true default=0;
	property name="click_count"        type="numeric" dbtype="int" required=true default=0;
	property name="unique_click_count" type="numeric" dbtype="int" required=true default=0;
	property name="bot_click_count"    type="numeric" dbtype="int" required=true default=0;
	property name="fail_count"         type="numeric" dbtype="int" required=true default=0;
	property name="spam_count"         type="numeric" dbtype="int" required=true default=0;
	property name="unsubscribe_count"  type="numeric" dbtype="int" required=true default=0;
}