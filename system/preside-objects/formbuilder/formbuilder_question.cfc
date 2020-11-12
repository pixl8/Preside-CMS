/**
 * @feature                 formbuilder
 * @datamanagerEnabled      true
 * @labelfield              field_id
 * @labelrenderer           formbuilder_question
 * @datamanagerGridFields   item_type,field_id,field_label,full_question_text,datemodified
 * @datamanagerSearchFields field_id,field_label,item_type,full_question_text
 */
component displayname="Form builder: global question" extends="preside.system.base.SystemPresideObject" {
	property name="item_type"          type="string"  dbtype="varchar" required=true  maxlength=100 batcheditable=false indexes="itemtype" renderer="formbuilderItemType";

	property name="field_id"           type="string"  dbtype="varchar" required=true  maxlength=30 uniqueindexes="fieldid" renderer="code" format="regex:^[a-z0-9_]+$";
	property name="field_label"        type="string"  dbtype="varchar" required=true  maxlength=50  batcheditable=false indexes="label";

	property name="full_question_text" type="string"  dbtype="varchar" required=false maxlength=800 batcheditable=false;
	property name="help_text"          type="string"  dbtype="text"    required=false               batcheditable=false;

	property name="item_type_config"   type="string"  dbtype="text"    required=false               batcheditable=false autofilter=false adminRenderer="none";

	property name="forms" relationship="many-to-many" relatedTo="formbuilder_form" relatedVia="formbuilder_formitem" relatedViaSourceFk="question" relatedViaTargetFk="form" adminViewGroup="forms" displayPropertyTitle=false cloneable=false;
	property name="responses" relationship="one-to-many" relatedTo="formbuilder_question_response" relationshipkey="question" adminRenderer="none" displayPropertyTitle=false cloneable=false;
}
