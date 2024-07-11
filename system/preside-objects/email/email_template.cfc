/**
 * Layout, subject and body of a single email, either system, transactional or marketing.
 *
 * @labelfield         name
 * @datamanagerEnabled true
 * @useDrafts          true
 * @feature            emailCenter
 */
component extends="preside.system.base.SystemPresideObject" displayname="Email template"  {
	property name="name"                type="string"  dbtype="varchar" maxlength=200 required=true uniqueindexes="templatename" renderer="emailName";
	property name="layout"              type="string"  dbtype="varchar" maxlength=200 required=false;
	property name="recipient_type"      type="string"  dbtype="varchar" maxlength=200 required=false;
	property name="subject"             type="string"  dbtype="varchar" maxlength=255 required=true;
	property name="from_address"        type="string"  dbtype="varchar" maxlength=255 required=false;
	property name="service_provider"    type="string"  dbtype="varchar" maxlength=200 required=false;
	property name="is_system_email"     type="boolean" dbtype="boolean"               required=false default=false;
	property name="track_clicks"        type="boolean" dbtype="boolean"               required=false default=false;
	property name="view_online"         type="boolean" dbtype="boolean"               required=false default=false;
	property name="save_content"        type="boolean" dbtype="boolean"               required=false default=false;
	property name="save_content_expiry" type="numeric" dbtype="int"                   required=false;

	property name="html_body"                 type="string"  dbtype="longtext";
	property name="text_body"                 type="string"  dbtype="longtext";
	property name="body_changed_from_default" type="boolean" dbtype="boolean" required=false default=false;

	property name="attachments" relationship="many-to-many" relatedto="asset" relatedVia="email_template_attachment" feature="assetManager";

	property name="variant_of"  relationship="many-to-one"  relatedto="email_template" required=false;
	property name="is_variant"  type="boolean" formula="case when ${prefix}variant_of is null then 0 else 1 end";

	property name="email_blueprint"  relationship="many-to-one" relatedTo="email_blueprint";
	property name="recipient_filter" relationship="many-to-one" relatedto="rules_engine_condition" ondelete="set-null-if-no-cycle-check" onupdate="cascade-if-no-cycle-check" feature="rulesEngine";

	property name="sending_method" type="string" dbtype="varchar" maxlength=20 required=false default="auto" enum="emailSendingMethod" ignoreChangesForVersioning=true renderer="emailSendingMethod";

	property name="sending_limit"         type="string"  dbtype="varchar" maxlength=20 required=false default="none" enum="emailSendingLimit" ignoreChangesForVersioning=true;
	property name="sending_limit_unit"    type="string"  dbtype="varchar" maxlength=20 required=false enum="timeUnit" ignoreChangesForVersioning=true;
	property name="sending_limit_measure" type="numeric" dbtype="int" required=false ignoreChangesForVersioning=true;

	property name="schedule_type"           type="string"  dbtype="varchar" maxlength=20 required=false default="none" enum="emailSendingScheduleType" ignoreChangesForVersioning=true;
	property name="schedule_date"           type="date"    dbtype="datetime"             required=false ignoreChangesForVersioning=true cloneable=false;
	property name="schedule_start_date"     type="date"    dbtype="datetime"             required=false ignoreChangesForVersioning=true;
	property name="schedule_end_date"       type="date"    dbtype="datetime"             required=false ignoreChangesForVersioning=true;
	property name="schedule_unit"           type="string"  dbtype="varchar" maxlength=20 required=false enum="timeUnit" ignoreChangesForVersioning=true;
	property name="schedule_measure"        type="numeric" dbtype="int"                  required=false ignoreChangesForVersioning=true;
	property name="schedule_sent"           type="boolean" dbtype="boolean"              required=false ignoreChangesForVersioning=true cloneable=false;
	property name="schedule_next_send_date" type="date"    dbtype="datetime"             required=false ignoreChangesForVersioning=true cloneable=false;

	property name="stats_collection_enabled"    type="boolean" dbtype="boolean" default=true indexes="statscollectionenabled";
	property name="stats_collection_enabled_on" type="numeric" dbtype="int"                  indexes="statscollectionenabledon";

	property name="last_sent_date" type="date" dbtype="datetime" required=false ignoreChangesForVersioning=true cloneable=false renderer="dateTimeRelative";
	property name="datemodified" renderer="dateTimeRelative";

	property name="send_logs"           relationship="one-to-many" relatedto="email_template_send_log"  relationshipKey="email_template" cloneable=false;
	property name="queued_emails"       relationship="one-to-many" relatedto="email_mass_send_queue"    relationshipKey="template"       cloneable=false feature="customEmailTemplates";
	property name="layout_config_items" relationship="one-to-many" relatedto="email_layout_config_item" relationshipKey="email_template" cloneable=true;

	property name="queued_email_count" formula="Count( distinct ${prefix}queued_emails.id )" type="numeric";
	property name="sent_count"         formula="Count( distinct ${prefix}send_logs.id )"     type="numeric";
	property name="send_date"          formula="Coalesce( ${prefix}schedule_next_send_date, ${prefix}schedule_date )"  type="date" dbtype="datetime" renderer="emailSendDate";
}