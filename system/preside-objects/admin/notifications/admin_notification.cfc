/**
 * The notification object is used to store notifications that can be consumed by admin users
 */
component output="false" extends="preside.system.base.SystemPresideObject" noLabel=true versioned=false displayname="Notification" {
	property name="topic"     type="string"  dbtype="varchar" maxlength="200" required=true indexes="topic";
	property name="type"      type="string"  dbtype="varchar" maxlength="10"  required=true indexes="type";
	property name="data"      type="string"  dbtype="text"                    required=false;
}