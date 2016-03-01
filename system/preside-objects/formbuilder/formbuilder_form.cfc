/**
 * The formbuilder_form object represents a single form within the form builder system
 *
 * @labelfield name
 */
component displayname="Form builder: form" extends="preside.system.base.SystemPresideObject" {
	property name="name"                   type="string"  dbtype="varchar" maxlength=255 required=true uniqueindexes="formname";
	property name="button_label"           type="string"  dbtype="varchar" maxlength=255 required=true;
	property name="form_submitted_message" type="string"  dbtype="text"                  required=true;
	property name="use_captcha"            type="boolean" dbtype="boolean"               required=false default=false;
	property name="description"            type="string"  dbtype="text"                  required=false;
	property name="locked"                 type="boolean" dbtype="boolean"               required=false default=false;
	property name="active"                 type="boolean" dbtype="boolean"               required=false default=false;
	property name="active_from"            type="date"    dbtype="datetime"              required=false;
	property name="active_to"              type="date"    dbtype="datetime"              required=false;

	property name="items" relationship="one-to-many" relatedto="formbuilder_formitem" relationshipKey="form";
}