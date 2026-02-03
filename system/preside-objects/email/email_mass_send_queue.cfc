/**
 * Object for storing a queue of emails to prepare and send
 *
 * @nolabel   true
 * @versioned false
 * @feature   customEmailTemplates
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="id" type="numeric" dbtype="bigint" generator="increment";

	property name="recipient" type="string" dbtype="varchar" maxlength=255 indexes="recipient" required=true uniqueindexes="queuedemail|1";
	property name="status"    type="string" dbtype="varchar" maxlength=10  indexes="status"    required=false enum="emailSendQueueStatus" generator="method:queuedStatus" generate="insert";
	property name="template"  relationship="many-to-one" relatedto="email_template"            required=true uniqueindexes="queuedemail|2";

	function queuedStatus() {
		return "queued";
	}
}