/**
 * The audit log object is used to store audit trail logs that are triggered by user actions in the administrator (or any other actions you wish to track).
 *
 * @nolabel
 * @versioned   false
 * @displayname Audit log
 *
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="detail"     type="string"  dbtype="text"                    required=true ;
	property name="action"     type="string"  dbtype="varchar" maxLength="100" required=true  indexes="action";
	property name="type"       type="string"  dbtype="varchar" maxLength="100" required=true  indexes="type";
	property name="record_id"  type="string"  dbtype="varchar" maxLength="100" required=false indexes="record_id";
	property name="uri"        type="string"  dbtype="varchar" maxLength="255" required=true;
	property name="user_ip"    type="string"  dbtype="varchar" maxLength="255" required=true;
	property name="user_agent" type="string"  dbtype="varchar" maxLength="255" required=false;

	property name="user" relationship="many-to-one" relatedTo="security_user" required="true" indexes="user";

	property name="datecreated" indexes="logged";
}