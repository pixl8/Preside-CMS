/**
 * The notification object is used to store notifications that can be consumed by admin users
 */
component output="false" extends="preside.system.base.SystemPresideObject" noLabel=true versioned=false displayname="Notification" {
	property name="key"       type="string"  dbtype="varchar" maxlength="200" required=true indexes="key";
	property name="type"      type="string"  dbtype="varchar" maxlength="10"  required=true indexes="type";
	property name="data"      type="string"  dbtype="text"                    required=false;
	property name="dismissed" type="boolean" dbtype="boolean"                 required=false default=false indexes="dismissed";
}