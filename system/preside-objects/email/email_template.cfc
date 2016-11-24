/**
 * Layout, subject and body of a single email, either system, transactional or marketing.
 *
 * @labelfield name
 */
component extends="preside.system.base.SystemPresideObject" displayname="Email template"  {
	property name="name"            type="string"  dbtype="varchar" maxlength=200 required=true uniqueindexes="templatename";
	property name="layout"          type="string"  dbtype="varchar" maxlength=200 required=true;
	property name="recipient_type"  type="string"  dbtype="varchar" maxlength=200 required=true;
	property name="subject"         type="string"  dbtype="varchar" maxlength=255 required=true;
	property name="from_address"    type="string"  dbtype="varchar" maxlength=255 required=false;
	property name="is_system_email" type="boolean" dbtype="boolean"               required=false default=false;

	property name="html_body" type="string" dbtype="longtext";
	property name="text_body" type="string" dbtype="longtext";

	property name="attachments" relationship="one-to-many" relatedto="email_template_attachment" relationshipKey="template";

	property name="recipient_filter" relationship="many-to-one" relatedto="rules_engine_filter";

	property name="sending_method" type="string" dbtype="varchar" maxlength=20 required=false default="auto" enum="emailSendingMethod";

	property name="sending_limit"         type="string"  dbtype="varchar" maxlength=20 required=false default="none" enum="emailSendingLimit";
	property name="sending_limit_measure" type="string"  dbtype="varchar" maxlength=20 required=false enum="timeMeasure";
	property name="sending_limit_unit"    type="numeric" dbtype="int" required=false;

	property name="schedule_type"    type="string"  dbtype="varchar" maxlength=20 required=false default="none" enum="emailSendingScheduleType";
	property name="schedule_date"    type="date"    dbtype="datetime"             required=false;
	property name="schedule_measure" type="string"  dbtype="varchar" maxlength=20 required=false enum="timeMeasure";
	property name="schedule_unit"    type="numeric" dbtype="int"                  required=false;


}