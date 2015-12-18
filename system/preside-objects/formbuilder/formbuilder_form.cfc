/**
 * @labelfield name
 */
component {
	property name="name"                   type="string"  dbtype="varchar" maxlength=255 required=true uniqueindexes="formname";
	property name="description"            type="string"  dbtype="text"                  required=false;
	property name="locked"                 type="boolean" dbtype="boolean"               required=false default=false;
	property name="active"                 type="boolean" dbtype="boolean"               required=false default=false;
	property name="active_from"            type="date"    dbtype="datetime"              required=false;
	property name="active_to"              type="date"    dbtype="datetime"              required=false;
	property name="form_submitted_message" type="string"  dbtype="text"                  required=false;
	property name="form_inactive_message"  type="string"  dbtype="text"                  required=false;
}