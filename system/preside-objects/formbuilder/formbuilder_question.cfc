/**
 * @feature            formbuilder2
 * @datamanagerEnabled true
 * @labelfield         field_id
 */
component displayname="Form builder: global question" extends="preside.system.base.SystemPresideObject" {
	property name="field_id"           type="string"  dbtype="varchar" required=true  maxlength=30 uniqueindexes="fieldid";
	property name="field_label"        type="string"  dbtype="varchar" required=true  maxlength=50  batcheditable=false indexes="label";

	property name="full_question_text" type="string"  dbtype="varchar" required=false maxlength=800 batcheditable=false;
	property name="help_text"          type="string"  dbtype="text"    required=false               batcheditable=false;

	property name="item_type"          type="string"  dbtype="varchar" required=true  maxlength=100 batcheditable=false indexes="itemtype";
	property name="item_type_config"   type="string"  dbtype="text"    required=false               batcheditable=false autofilter=false;
}