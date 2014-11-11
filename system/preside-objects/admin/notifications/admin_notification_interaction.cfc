/**
 * The notification interaction object is used to store details of a single user's interactions with a notificatio
 */
component output="false" extends="preside.system.base.SystemPresideObject" noLabel=true versioned=false displayname="Notification interaction" {
	property name="admin_notification" relationship="many-to-one" required=true uniqueindexes="notificationUser|1";
	property name="security_user"      relationship="many-to-one" required=true uniqueindexes="notificationUser|2";

	property name="read"      type="boolean" dbtype="boolean" required=false default=false indexes="read";
	property name="dismissed" type="boolean" dbtype="boolean" required=false default=false indexes="dismissed";
}