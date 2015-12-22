/**
 * The formbuilder_formsection object represents a "section" within
 * a form builder form.
 *
 * @nolabel
 */
component displayname="Form builder: section" extends="preside.system.base.SystemPresideObject" {
	property name="form" relationship="many-to-one" relatedto="formbuilder_form" required=true uniqueindexes="formsection|1";
	property name="sort_order" type="numeric" dbtype="int" required=true uniqueindexes="formsection|2";

	property name="items" relationship="one-to-many" relatedto="formbuilder_formitem" relationshipKey="section";
}