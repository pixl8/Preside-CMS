/**
 * A log of interactions with sent emails
 *
 * @versioned                   false
 * @nolabel                     true
 * @datamanagerDefaultSortOrder datecreated
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="message" relationship="many-to-one" relatedto="email_template_send_log" required=true;

	property name="activity_type" type="string" dbtype="varchar" maxlength=15   required=true enum="emailActivityType" indexes="activitytype";
	property name="user_ip"       type="string" dbtype="varchar" maxLength=255  required=true;
	property name="user_agent"    type="string" dbtype="text"                   required=false;
	property name="extra_data"    type="string" dbtype="longtext";
	property name="link"          type="string" dbtype="varchar" maxlength=800 renderer="emailClickedLink" dataExportRenderer="emailClickedLink";
	property name="code"          type="string" dbtype="varchar" maxlength=20  indexes="errorcode";
	property name="reason"        type="string" dbtype="varchar" maxlength=800;
}