/**
 * The notification subscription object is used to store details of a single user's subscriptions to particular notification topics
 */
component output="false" extends="preside.system.base.SystemPresideObject" noLabel=true versioned=false displayname="Notification consumer" {
	property name="security_user" required=true uniqueindexes="notificationSubscriber|1" relationship="many-to-one"  ondelete="cascade";
	property name="topic"         required=true uniqueindexes="notificationSubscriber|2" type="string" dbtype="varchar" maxlength=100 indexes="topic";
}