/**
 * @versioned                       false
 * @datamanagerEnabled              true
 * @datamanagerGridFields           label_text,filter,style,icon,sort_order
 * @datamanagerDefaultSortOrder     sort_order,label_text
 * @datamanagerDisallowedOperations clone,batchedit,view
 * @labelfield                      label_text
 * @feature                         customFields and rulesEngine
 */
component displayname="Custom field conditional rule" extends="preside.system.base.SystemPresideObject" {
	property name="field"      relationship="many-to-one" relatedto="custom_field" required=true ondelete="cascade" uniqueindexes="fieldsort|1";
	property name="filter"     relationship="many-to-one" relatedto="rules_engine_condition" required=false ondelete="set-null-if-no-cycle-check" control="customFieldFilterPicker";
	property name="label_text" type="string"  dbtype="varchar" maxlength=100 required=true;
	property name="style"      type="string"  dbtype="varchar" maxlength=20  required=false default="default" enum="customFieldConditionalStyle";
	property name="icon"       type="string"  dbtype="varchar" maxlength=50  required=false;
	property name="sort_order" type="numeric" dbtype="int" required=true uniqueindexes="fieldsort|2";
}
