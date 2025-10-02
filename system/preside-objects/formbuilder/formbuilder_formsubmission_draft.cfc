/**
 * @nolabel   true
 * @versioned false
 * @feature   formBuilder
 */
component displayname="Form builder: form submission draft" extends="preside.system.base.SystemPresideObject" {

	property name="form"         relationship="many-to-one" relatedto="formbuilder_form" required=true;
	property name="submitted_by" relationship="many-to-one" relatedTo="website_user"     required=false renderer="websiteUser" onDelete="set-null-if-no-cycle-check" onUpdate="cascade-if-no-cycle-check" feature="websiteUsers";

	property name="submitted_data" type="string" dbtype="text" required=false renderer="formbuilderSubmission";

}