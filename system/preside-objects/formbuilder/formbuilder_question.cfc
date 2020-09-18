/**
 * @feature                 formbuilder2
 * @labelfield              field_id
 * @datamanagerEnabled      true
 * @datamanagerGridFields   item_type,field_id,field_label,full_question_text,datemodified
 * @datamanagerSearchFields field_id,field_label,item_type,full_question_text
 */
component displayname="Form builder: global question" extends="preside.system.base.SystemPresideObject" {
	property name="field_id"           type="string"  dbtype="varchar" required=true  maxlength=30 uniqueindexes="fieldid" renderer="code";
	property name="field_label"        type="string"  dbtype="varchar" required=true  maxlength=50  batcheditable=false indexes="label";

	property name="full_question_text" type="string"  dbtype="varchar" required=false maxlength=800 batcheditable=false;
	property name="help_text"          type="string"  dbtype="text"    required=false               batcheditable=false;

	property name="item_type"          type="string"  dbtype="varchar" required=true  maxlength=100 batcheditable=false indexes="itemtype" renderer="formbuilderItemType";
	property name="item_type_config"   type="string"  dbtype="text"    required=false               batcheditable=false autofilter=false;
}