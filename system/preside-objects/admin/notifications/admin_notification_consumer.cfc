/**
 * The notification consumer object is used to store details of a single user's interactions with a notification
 */
component output="false" extends="preside.system.base.SystemPresideObject" noLabel=true versioned=false displayname="Notification consumer" {
	property name="admin_notification" relationship="many-to-one" required=true uniqueindexes="notificationUser|1" ondelete="cascade";
	property name="security_user"      relationship="many-to-one" required=true uniqueindexes="notificationUser|2" ondelete="cascade";

	property name="read" type="boolean" dbtype="boolean" required=false default=false indexes="read";
}