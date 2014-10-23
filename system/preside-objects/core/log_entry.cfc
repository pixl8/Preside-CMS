/**
 * The log_entry object stores any log entries from logs using the
 * the PresideDbAppender log appender through logbox.
 *
 */

component extends="preside.system.base.SystemPresideObject" noLabel=true output=false versioned=false displayname="Log entry" {
	property name="id"          type="numeric" dbtype="bigint"  generator="increment";
	property name="severity"    type="string"  dbtype="varchar" maxLength="20" indexes="severity" required=true;
	property name="category"    type="string"  dbtype="varchar" maxLength="50" indexes="category" required=false default="none";
	property name="message"     type="string"  dbtype="text";
	property name="extra_info"  type="string"  dbtype="text";

	property name="admin_user_id" relationship="many-to-one" relatedTo="security_user";
	property name="web_user_id"   relationship="many-to-one" relatedTo="website_user";

	property name="datemodified" deleted=true;
}