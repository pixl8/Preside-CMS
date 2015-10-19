/**
 * The notification subscription object is used to store details of a single user's subscriptions to particular notification topics
 *
 * @nolabel   true
 * @versioned false
 */
component extends="preside.system.base.SystemPresideObject" displayname="Notification subscription" {
	property name="security_user"           required=true  uniqueindexes="notificationSubscriber|1" relationship="many-to-one"  ondelete="cascade";
	property name="topic"                   required=true  uniqueindexes="notificationSubscriber|2" type="string" dbtype="varchar" maxlength=100 indexes="topic";
	property name="get_email_notifications" required=false type="boolean" dbtype="boolean" indexes="emailnotifiers" default=false;
}