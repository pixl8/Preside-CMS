/**
 * Represents the running of an adhoc task
 *
 * @nolabel
 * @versioned  false
 *
 */
component extends="preside.system.base.SystemPresideObject"  {
	property name="event"          type="string"  dbtype="varchar"   maxlength=255 required=true;
	property name="result_viewlet" type="string"  dbtype="varchar"   maxlength=255 required=false;
	property name="label_viewlet"  type="string"  dbtype="longtext"                required=false;
	property name="event_args"     type="string"  dbtype="longtext"                required=false;
	property name="result"         type="string"  dbtype="longtext"                required=false;
	property name="is_public"      type="boolean" dbtype="boolean"                 required=false default=false;
	property name="expires"        type="date"    dbtype="datetime"                required=false;

	property name="status"              type="string"  dbtype="varchar"   maxlength=50  required=false default="pending" enum="adhocTaskStatus";
	property name="progress_percentage" type="numeric" dbtype="int"                     required=false default=0;
	property name="retry_intervals"     type="string"  dbtype="text"                    required=false;
	property name="attempt_number"      type="numeric" dbtype="int"                     required=false default=1;

	property name="owner" relationship="many-to-one" relatedto="security_user" required=false;
}