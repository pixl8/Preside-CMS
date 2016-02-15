/**
 * The formbuilder_formaction object represents an individual action that is executed when an instance of a form is submitted.
 * This could be an action to send an email, POST to a webhook, etc.
 *
 * @nolabel
 */
component displayname="Form builder: Action" extends="preside.system.base.SystemPresideObject" {
	property name="form" relationship="many-to-one" relatedto="formbuilder_form" required=true indexes="form,sortorder|1";

	property name="sort_order"    type="numeric" dbtype="int"     required=true indexes="sortorder|2";
	property name="action_type"   type="string"  dbtype="varchar" required=true maxlength=100;
	property name="configuration" type="string"  dbtype="text"    required=false;
}