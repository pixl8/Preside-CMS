/**
 * The audit log object is used to store audit trail logs that are triggered by user actions in the administrator (or any other actions you wish to track).
 */
component output="false" extends="preside.system.base.SystemPresideObject" labelfield="detail" versioned=false displayname="Audit log" {
	property name="detail"     type="string"  dbtype="varchar" maxLength="200" required=true;
	property name="source"     type="string"  dbtype="varchar" maxLength="100" required=true;
	property name="action"     type="string"  dbtype="varchar" maxLength="100" required=true;
	property name="type"       type="string"  dbtype="varchar" maxLength="100" required=true;
	property name="instance"   type="string"  dbtype="varchar" maxLength="200" required=true;
	property name="uri"        type="string"  dbtype="varchar" maxLength="255" required=true;
	property name="user_ip"    type="string"  dbtype="varchar" maxLength="255" required=true;
	property name="user_agent" type="string"  dbtype="varchar" maxLength="255" required=false;

	property name="user" relationship="many-to-one" relatedTo="security_user" required="true";

	property name="datecreated" indexes="logged"; // add a DB index to the default 'datecreated' property
}