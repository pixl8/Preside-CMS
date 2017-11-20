/**
 * Represents the running of an adhoc task
 *
 * @nolabel
 * @versioned  false
 *
 */
component extends="preside.system.base.SystemPresideObject"  {
	property name="event"          type="string"  dbtype="varchar"   maxlength=255 required=true;
	property name="event_args"     type="string"  dbtype="longtext"                required=false;
	property name="result"         type="string"  dbtype="longtext"                required=false;

	property name="status"              type="string"  dbtype="varchar"   maxlength=50  required=false default="pending" enum="adhocTaskStatus";
	property name="progress_percentage" type="numeric" dbtype="int"                     required=false default=0;

	property name="discard_on_complete" type="boolean" dbtype="boolean" required=false default=false;

	property name="admin_owner" relationship="many-to-one" relatedto="security_user" required=false;
	property name="web_owner"   relationship="many-to-one" relatedto="website_user"  required=false;
}