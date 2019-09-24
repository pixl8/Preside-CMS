/**
 * The formbuilder_formsubmission object represents a single submission of a form builder form
 *
 * @nolabel
 * @versioned false
 */
component displayname="Form builder: form" extends="preside.system.base.SystemPresideObject" {
	property name="form"         relationship="many-to-one" relatedto="formbuilder_form" required=true;
	property name="submitted_by" relationship="many-to-one" relatedTo="website_user"     required=false renderer="websiteUser";

	property name="submitted_data" type="string" dbtype="text"                  required=true  renderer="formbuilderSubmission";
	property name="form_instance"  type="string" dbtype="varchar" maxlength=200 required=false;
	property name="ip_address"     type="string" dbtype="varchar" maxlength=50  required=false;
	property name="user_agent"     type="string" dbtype="text"                  required=false;
}