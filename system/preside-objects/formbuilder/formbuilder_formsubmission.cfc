/**
 * The formbuilder_formsubmission object represents a single submission of a form builder form
 *
 * @nolabel   true
 * @versioned false
 * @feature   formBuilder
 */
component displayname="Form builder: form" extends="preside.system.base.SystemPresideObject" {
	property name="form"         relationship="many-to-one" relatedto="formbuilder_form" required=true;
	property name="submitted_by" relationship="many-to-one" relatedTo="website_user"     required=false renderer="websiteUser" ondelete="set-null-if-no-cycle-check" onupdate="cascade-if-no-cycle-check" feature="websiteUsers";

	property name="submitted_data" type="string" dbtype="text"                  required=false  renderer="formbuilderSubmission";
	property name="form_instance"  type="string" dbtype="varchar" maxlength=200 required=false;
	property name="ip_address"     type="string" dbtype="varchar" maxlength=50  required=false;
	property name="user_agent"     type="string" dbtype="text"                  required=false;
}