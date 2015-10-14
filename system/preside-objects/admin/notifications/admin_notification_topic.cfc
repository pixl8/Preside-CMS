/**
 * The notification topic object is used to store global configuration for a given notification topic
 *
 * @noLabel   true
 * @versioned false
 */
component output="false" extends="preside.system.base.SystemPresideObject" displayname="Notification topic" {
	property name="topic"                 type="string"  dbtype="varchar" maxlength=200 required=true uniqueindex="topic";
	property name="send_to_email_address" type="string"  dbtype="text"                  required=false;
	property name="save_in_cms"           type="boolean" dbtype="boolean"               required=false default=true;

	property name="available_to_groups" relationship="many-to-many" relatedTo="security_group" relatedVia="admin_notification_topic_user_group";
}