/**
 * A log of interactions with sent emails
 *
 * @versioned                   false
 * @nolabel                     true
 * @datamanagerDefaultSortOrder datecreated
 * @datamanagerSearchFields     message.recipient,message$email_template.name,activity_type,link,link_title,link_body,reason
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="message" relationship="many-to-one" relatedto="email_template_send_log" required=true indexes="logdatecreated|1,logactivitytype|1";

	property name="datecreated" indexes="logdatecreated|2";
	property name="activity_type" type="string" dbtype="varchar" maxlength=15   required=true enum="emailActivityType" indexes="activitytype,logactivitytype|2";
	property name="user_ip"       type="string" dbtype="varchar" maxLength=255  required=true;
	property name="user_agent"    type="string" dbtype="text"                   required=false;
	property name="extra_data"    type="string" dbtype="longtext";
	property name="link"          type="string" dbtype="varchar" maxlength=800;
	property name="link_title"    type="string" dbtype="text";
	property name="link_body"     type="string" dbtype="text";
	property name="code"          type="string" dbtype="varchar" maxlength=20  indexes="errorcode";
	property name="reason"        type="string" dbtype="varchar" maxlength=800;

	property name="link_summary" formula="case when ${prefix}link_title is null and ${prefix}link_body is null then ${prefix}link else concat( coalesce( ${prefix}link_title, ${prefix}link_body ), ' (', ${prefix}link, ')' ) end";
}